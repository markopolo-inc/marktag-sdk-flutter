import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/models/marktag_events.dart';
import 'package:marktag/src/services/campaign_attribution_service.dart';
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/services/push_notification_tracking_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:marktag/src/services/user_service.dart';
import 'package:meta/meta.dart';

/// Flutter SDK for Marktag.
class Marktag {
  Marktag._();

  /// The singleton instance of the [Marktag] class.
  static final Marktag instance = Marktag._();

  /// Initializes the [Marktag] instance.
  ///
  /// [tag] is the Marktag host (e.g. `mtag.imti.tech` or `mtag.markopolo.ai`).
  ///
  /// Pass [tagId] for client-side (web) mode where a shared host is used and
  /// the tag id identifies the tenant
  /// (e.g. `tag: 'mtag.markopolo.ai', tagId: 'y5mpbm'`).
  ///
  /// Pass [serverId] for server-side (mobile) mode where the tenant is
  /// identified by an explicit server id
  /// (e.g. `tag: 'mtag.imti.tech', serverId: '21j3eM'`).
  void init({
    required String tag,
    String? tagId,
    String? serverId,
    bool? enableLogging,
  }) {
    if (_payloadService != null) {
      loggerService?.debugLog(
        'Marktag.instance.init() was already called; ignoring this '
        'repeated call. init() may only run once per app process.',
      );
      return;
    }
    loggerService = LoggerService(
      name: 'Marktag',
      enabled: enableLogging ?? true,
    );
    if (!RegExp(r'^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$').hasMatch(tag)) {
      loggerService?.debugLog(
        'Invalid tag: $tag.'
        ' Tags should be in the format of "tag.website.com"',
      );
      return;
    }
    _tag = tag;
    final storageService = StorageService(logger: loggerService);
    _userService = UserService(
      storageService: storageService,
      logger: loggerService,
    );
    _eventService = EventService(tag: tag, tagId: tagId, logger: loggerService);
    _campaignAttributionService = CampaignAttributionService(
      storageService: storageService,
      logger: loggerService,
    );
    _payloadService = PayloadService(
      userService: _userService,
      tagId: tagId,
      serverId: serverId,
      ipService: IPService(logger: loggerService),
      logger: loggerService,
      campaignAttributionService: _campaignAttributionService,
    );
    _initNotificationTracking();
  }

  String? _tag;

  /// The [EventService] instance.
  EventService? _eventService;

  /// The [PayloadService] instance.
  PayloadService? _payloadService;

  /// The [CampaignAttributionService] instance.
  CampaignAttributionService? _campaignAttributionService;

  /// The [LoggerService] instance.
  LoggerService? loggerService;

  /// The [UserService] instance.
  late UserService _userService;

  /// The [PushNotificationTrackingService] instance.
  PushNotificationTrackingService? _pushTrackingService;

  /// Test-only getter for whether [init] has already run. Use only in tests.
  @visibleForTesting
  bool get isInitializedForTest => _payloadService != null;

  /// Test-only getter for the configured tag. Use only in tests.
  @visibleForTesting
  String? get tagForTest => _tag;

  /// Logs an event to the Marktag server.
  Future<void> logEvent(MarktagEvent event) async {
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Identifies a user with the given [email], [name], and [phone].
  Future<void> identifyUser({
    String? email,
    String? name,
    String? phone,
  }) async {
    await _userService.setUser(email: email, name: name, phone: phone);
  }

  /// Logs a login event.
  Future<void> logLogin({
    String? email,
    String? name,
    String? phone,
  }) async {
    await _userService.setUser(email: email, name: name, phone: phone);
    final event = MarktagEvent(
      event: MarktagEvents.login,
      metadata: {
        'email': email,
        'name': name,
        'phone': phone,
      },
    );
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Logs a search event.
  Future<void> logSearch(String searchText) async {
    final event = MarktagEvent(
      event: MarktagEvents.search,
      metadata: {
        'search_term': searchText,
      },
    );
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Logs a signup event.
  Future<void> logSignup({
    String? email,
    String? name,
    String? phone,
  }) async {
    await _userService.setUser(email: email, name: name, phone: phone);
    final event = MarktagEvent(
      event: MarktagEvents.signup,
      metadata: {
        'email': email,
        'name': name,
        'phone': phone,
      },
    );
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Logs a page view event.
  Future<void> logPageView(String page) async {
    final event = MarktagEvent(
      event: MarktagEvents.pageView,
      pageUrl: page,
    );
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  void _initNotificationTracking() {
    final eventService = _eventService;
    final payloadService = _payloadService;
    final campaignAttributionService = _campaignAttributionService;
    if (eventService == null ||
        payloadService == null ||
        campaignAttributionService == null) {
      return;
    }

    _pushTrackingService = PushNotificationTrackingService(
      eventService: eventService,
      payloadService: payloadService,
      campaignAttributionService: campaignAttributionService,
      logger: loggerService,
    );
    _pushTrackingService!.initialize();
  }

  /// Sends an event to the Marktag server.
  Future<void> _sendEvent(Map<String, dynamic>? payload) async {
    try {
      if (_tag == null) {
        loggerService?.debugLog(
          'Marktag must be initialized with init() before calling any methods',
        );
        return;
      }

      if (payload == null) {
        return;
      }
      await _eventService?.markEvent(payload);
    } on Object catch (e) {
      loggerService?.debugLog(
        'Error sending event: $e',
        error: e,
      );
    }
  }
}
