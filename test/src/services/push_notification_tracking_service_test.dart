import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/services/campaign_attribution_service.dart';
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/services/push_notification_tracking_service.dart';
import 'package:mocktail/mocktail.dart';

class MockEventService extends Mock implements EventService {}

class MockPayloadService extends Mock implements PayloadService {}

class MockCampaignAttributionService extends Mock
    implements CampaignAttributionService {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  setUpAll(() {
    registerFallbackValue(MarktagEvent(event: 'Fallback'));
  });

  late MockEventService eventService;
  late MockPayloadService payloadService;
  late MockCampaignAttributionService campaignAttributionService;
  late MockLoggerService logger;
  late PushNotificationTrackingService service;

  setUp(() {
    eventService = MockEventService();
    payloadService = MockPayloadService();
    campaignAttributionService = MockCampaignAttributionService();
    logger = MockLoggerService();
    when(() => logger.debugLog(any())).thenReturn(null);
    when(
      () => logger.debugLog(any(), error: any(named: 'error')),
    ).thenReturn(null);
    service = PushNotificationTrackingService(
      eventService: eventService,
      payloadService: payloadService,
      campaignAttributionService: campaignAttributionService,
      logger: logger,
    );
  });

  group('PushNotificationTrackingService', () {
    test('does nothing when the message has no campaignId', () async {
      const message = RemoteMessage(data: {'foo': 'bar'});

      await service.trackNotificationEventForTest(message, 'opened');

      verifyNever(() => payloadService.createPayload(any()));
      verifyNever(() => eventService.markEvent(any()));
      verifyNever(
        () => campaignAttributionService.recordClick(
          campaignId: any(named: 'campaignId'),
          msid: any(named: 'msid'),
          contentId: any(named: 'contentId'),
          nodeId: any(named: 'nodeId'),
        ),
      );
    });

    test(
      'createPayload -> markEvent -> recordClick, in order, with the '
      'post-rotation currentMsid',
      () async {
        const message = RemoteMessage(
          data: {
            'campaignId': 'camp_789',
            'messageId': 'msg_456',
            'contentId': 'content_abc',
            'nodeId': 'node_1',
            'companyId': 'co_1',
            'shortCode': 'sc_xyz',
          },
        );
        final payload = {'event': 'PushNotificationTrack'};

        when(
          () => payloadService.createPayload(any()),
        ).thenAnswer((_) async => payload);
        when(
          () => eventService.markEvent(payload),
        ).thenAnswer((_) async => <String, dynamic>{});
        when(() => payloadService.currentMsid).thenReturn('msid-post-rotation');
        when(
          () => campaignAttributionService.recordClick(
            campaignId: any(named: 'campaignId'),
            msid: any(named: 'msid'),
            contentId: any(named: 'contentId'),
            nodeId: any(named: 'nodeId'),
          ),
        ).thenAnswer((_) async {});

        await service.trackNotificationEventForTest(message, 'opened');

        verifyInOrder([
          () => payloadService.createPayload(any()),
          () => eventService.markEvent(payload),
          () => campaignAttributionService.recordClick(
            campaignId: 'camp_789',
            msid: 'msid-post-rotation',
            contentId: 'content_abc',
            nodeId: 'node_1',
          ),
        ]);
      },
    );

    test(
      'recordClick exception is caught and logged, does not propagate',
      () async {
        const message = RemoteMessage(data: {'campaignId': 'camp_789'});
        final payload = {'event': 'PushNotificationTrack'};

        when(
          () => payloadService.createPayload(any()),
        ).thenAnswer((_) async => payload);
        when(
          () => eventService.markEvent(payload),
        ).thenAnswer((_) async => <String, dynamic>{});
        when(() => payloadService.currentMsid).thenReturn('msid-1');
        when(
          () => campaignAttributionService.recordClick(
            campaignId: any(named: 'campaignId'),
            msid: any(named: 'msid'),
            contentId: any(named: 'contentId'),
            nodeId: any(named: 'nodeId'),
          ),
        ).thenThrow(Exception('storage failure'));

        await expectLater(
          service.trackNotificationEventForTest(message, 'opened'),
          completes,
        );
      },
    );
  });
}
