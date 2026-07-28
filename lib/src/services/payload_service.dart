import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:marktag/src/models/campaign_context.dart';
import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/services/campaign_attribution_service.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/user_service.dart';
import 'package:uuid/uuid.dart';

/// A service responsible for creating payloads for MarkTag events.
class PayloadService {
  /// Creates an instance of [PayloadService].
  ///
  /// Requires a [UserService] to fetch user data and an optional
  /// [LoggerService] for logging purposes. [ipService] is only used in
  /// server-side mode (when [tagId] is omitted) to capture the originating
  /// IP/geo via Cloudflare trace.
  PayloadService({
    required this.userService,
    this.tagId,
    this.serverId,
    IPService? ipService,
    LoggerService? logger,
    CampaignAttributionService? campaignAttributionService,
    @visibleForTesting Future<String?> Function()? resolveDeviceId,
    @visibleForTesting Uuid? uuidGenerator,
    @visibleForTesting DateTime Function()? now,
    @visibleForTesting Duration? sessionTimeout,
  }) : _resolveDeviceId = resolveDeviceId,
       _ipService = ipService,
       _uuid = uuidGenerator ?? const Uuid(),
       _sessionId = (uuidGenerator ?? const Uuid()).v4(),
       _msid = (uuidGenerator ?? const Uuid()).v4(),
       _now = now ?? DateTime.now,
       _sessionTimeout = sessionTimeout ?? _defaultSessionTimeout,
       _campaignAttributionService =
           campaignAttributionService ?? CampaignAttributionService(),
       logger = logger ?? LoggerService(name: 'PayloadService');

  static const Duration _defaultSessionTimeout = Duration(minutes: 30);

  /// The service used to fetch user information.
  final UserService userService;

  /// The tenant identifier for client-side mode (sent as `clientId` in the
  /// payload). Mutually exclusive with [serverId].
  final String? tagId;

  /// The tenant identifier for server-side mode (sent as `serverId` in the
  /// payload). Mutually exclusive with [tagId].
  final String? serverId;

  /// The logger used for logging messages.
  final LoggerService logger;

  final Future<String?> Function()? _resolveDeviceId;
  final IPService? _ipService;
  final CampaignAttributionService _campaignAttributionService;
  final Uuid _uuid;
  final DateTime Function() _now;
  final Duration _sessionTimeout;

  /// A per-process id, minted once when this [PayloadService] is
  /// constructed and never rotated. Distinct from [currentMsid], which
  /// rotates on inactivity.
  final String _sessionId;

  /// The current activity-session id. Rotates in [createPayload] once more
  /// than [_sessionTimeout] has elapsed since the last tracked event.
  String _msid;

  /// `null` until the first [createPayload] call in this process.
  DateTime? _lastEventAt;

  /// Test-only getter for the configured [IPService]. Use only in tests.
  @visibleForTesting
  IPService? get ipService => _ipService;

  /// The current (possibly just-rotated) activity-session id.
  ///
  /// Reading this does not itself trigger rotation — only [createPayload]
  /// does.
  String get currentMsid => _msid;

  void _rotateMsidIfNeeded(DateTime now) {
    final lastEventAt = _lastEventAt;
    if (lastEventAt != null && now.difference(lastEventAt) > _sessionTimeout) {
      _msid = _uuid.v4();
    }
    _lastEventAt = now;
  }

  /// Creates a payload for a given [MarktagEvent].
  ///
  /// The payload includes user information, IP information, and event details.
  /// Returns a [Future] that completes with the payload as a [Map].
  Future<Map<String, dynamic>> createPayload(MarktagEvent event) async {
    // Captured once, before any await: keeps the rotation decision and the
    // is_same_session/*_since_click fields below self-consistent even if a
    // slow network call (e.g. getIpInfo()) straddles the session boundary.
    final now = _now();
    _rotateMsidIfNeeded(now);

    if (event.email != null || event.phone != null) {
      await userService.setUser(
        email: event.email,
        phone: event.phone,
      );
    }
    final user = await userService.getUser();
    final resolveDeviceId = _resolveDeviceId;
    final deviceId = resolveDeviceId != null
        ? await resolveDeviceId()
        : await _readDeviceId();
    final isClientMode = tagId != null && tagId!.isNotEmpty;
    // Server-side mode requires `x-cf-ip` / `x-cf-loc` keys in the body even
    // if empty — the ingestion server rejects events without them. Fetch
    // them from Cloudflare trace; on failure, fall back to empty strings so
    // the event still goes through.
    var cfIp = '';
    var cfLoc = '';
    final ipService = _ipService;
    if (!isClientMode && ipService != null) {
      try {
        final ipInfo = await ipService.getIpInfo();
        cfIp = ipInfo.ip;
        cfLoc = ipInfo.loc;
      } on Object catch (e) {
        logger.debugLog('Could not fetch IP info, sending empty values: $e');
      }
    }
    final hasServerId = serverId != null && serverId!.isNotEmpty;
    CampaignContext? campaignContext;
    try {
      campaignContext = await _campaignAttributionService.getActiveContext();
    } on Object catch (e) {
      logger.debugLog('Could not read campaign context: $e');
    }
    Map<String, dynamic>? attribution;
    if (campaignContext != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(campaignContext.capturedAtMs),
      );
      attribution = {
        'utm': {
          'utm_campaign': campaignContext.campaignId,
          'utm_medium': 'push',
          'utm_source': 'markopolo',
          'utm_content': campaignContext.contentId,
          'utm_node': campaignContext.nodeId,
        },
        'is_same_session': campaignContext.msid == _msid,
        'minutes_since_click': elapsed.inMinutes,
        'days_since_click': elapsed.inDays,
      };
    }
    final payload = <String, dynamic>{
      'event_source': kIsWeb ? 'web' : 'mobile',
      if (isClientMode) 'clientId': tagId,
      if (isClientMode) 'isClient': true,
      if (!isClientMode && hasServerId) 'serverId': serverId,
      if (!isClientMode && hasServerId) 'isServer': true,
      if (!isClientMode) 'x-cf-ip': cfIp,
      if (!isClientMode) 'x-cf-loc': cfLoc,
      'muid': deviceId,
      'sessionId': _sessionId,
      'msid': _msid,
      'attribution': ?attribution,
      ...user.toJson(),
      'event': event.event,
      'pageUrl': event.pageUrl,
      'deviceId': deviceId,
      'products': event.items?.map((e) => e.toJson()).toList(),
      ...?event.metadata,
    };
    logger.debugLog('Payload: $payload');
    return payload;
  }

  Future<String?> _readDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      return web.userAgent;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }
}
