import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/models/marktag_event.dart';

class PushNotificationTrackingService {
  PushNotificationTrackingService({
    required EventService eventService,
    required PayloadService payloadService,
    LoggerService? logger,
  }) : _eventService = eventService,
       _payloadService = payloadService,
       _logger = logger ?? LoggerService(name: 'PushNotificationTracking');

  final EventService _eventService;
  final PayloadService _payloadService;
  final LoggerService _logger;

  void initialize() {
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[Markopolo] WARNING: Firebase is not initialized. '
        'Push notification tracking will be disabled. '
        'To enable it, call Firebase.initializeApp() before '
        'Marktag.instance.init(). ',
      );
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      _attachNotificationListeners(messaging);
      _logger.debugLog('Push notification tracking initialized');
    } catch (e) {
      debugPrint(
        '[Markopolo] Firebase not available, '
        'skipping notification tracking: $e',
      );
    }
  }

  void _attachNotificationListeners(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _trackNotificationEvent(message, 'opened');
    });

    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _trackNotificationEvent(message, 'opened');
      }
    });
  }

  Future<void> _trackNotificationEvent(
    RemoteMessage message,
    String eventType,
  ) async {
    final data = message.data;

    if (!data.containsKey('campaignId')) return;

    try {
      final event = MarktagEvent(
        event: 'PushNotificationTrack',
        metadata: {
          'campaignId': data['campaignId'] ?? '',
          'messageId': data['messageId'] ?? '',
          'contentId': data['contentId'] ?? '',
          'muid': data['muid'] ?? '',
          'platform': data['platform'] ?? '',
          'step': data['step'] ?? '1',
          'companyId': data['companyId'] ?? '',
          'shortCode': data['shortCode'] ?? '',
          'trackingType': eventType,
        },
      );

      final payload = await _payloadService.createPayload(event);
      await _eventService.markEvent(payload);

      _logger.debugLog(
        'Push notification $eventType event tracked for '
        'campaign: ${data['campaignId']}',
      );
    } on Object catch (e) {
      _logger.debugLog(
        'Error tracking push notification event: $e',
        error: e,
      );
    }
  }
}
