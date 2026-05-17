import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:marktag/src/models/marktag_event.dart';
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
    @visibleForTesting Future<String?> Function()? resolveDeviceId,
  })  : _resolveDeviceId = resolveDeviceId,
        _ipService = ipService,
        _sessionId = const Uuid().v4(),
        logger = logger ?? LoggerService(name: 'PayloadService');

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
  final String _sessionId;

  /// Test-only getter for the configured [IPService]. Use only in tests.
  @visibleForTesting
  IPService? get ipService => _ipService;

  /// Creates a payload for a given [MarktagEvent].
  ///
  /// The payload includes user information, IP information, and event details.
  /// Returns a [Future] that completes with the payload as a [Map].
  Future<Map<String, dynamic>> createPayload(MarktagEvent event) async {
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
      'msid': const Uuid().v4(),
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
