import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/campaign_context.dart';
import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/models/user.dart';
import 'package:marktag/src/services/campaign_attribution_service.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/services/user_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockUserService extends Mock implements UserService {}

class MockIPService extends Mock implements IPService {}

class MockLoggerService extends Mock implements LoggerService {}

class MockCampaignAttributionService extends Mock
    implements CampaignAttributionService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late PayloadService payloadService;
  late MockUserService mockUserService;
  late MockIPService mockIPService;
  late MockLoggerService mockLogger;
  late MockCampaignAttributionService mockCampaignAttributionService;
  late MockUuid mockUuid;
  late int uuidCallCount;

  setUp(() {
    mockUserService = MockUserService();
    mockIPService = MockIPService();
    mockLogger = MockLoggerService();
    mockCampaignAttributionService = MockCampaignAttributionService();
    mockUuid = MockUuid();
    uuidCallCount = 0;
    when(() => mockUuid.v4()).thenAnswer((_) => 'uuid-${uuidCallCount++}');
    when(
      () => mockCampaignAttributionService.getActiveContext(),
    ).thenAnswer((_) async => null);
    payloadService = PayloadService(
      userService: mockUserService,
      ipService: mockIPService,
      logger: mockLogger,
      campaignAttributionService: mockCampaignAttributionService,
      resolveDeviceId: () async => null,
      uuidGenerator: mockUuid,
    );
  });

  group('PayloadService', () {
    test('constructor initializes dependencies correctly', () {
      expect(payloadService.userService, equals(mockUserService));
      expect(payloadService.ipService, equals(mockIPService));
      expect(payloadService.logger, equals(mockLogger));
    });

    group('createPayload', () {
      test('creates payload with all event data correctly', () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
          email: 'test@example.com',
          phone: '1234567890',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        final testEvent = MarktagEvent(
          event: 'TestEvent',
          pageUrl: 'https://test.com/page',
          items: [
            const MarktagEventItem(
              id: 'test-id',
              name: 'Test Product',
              category: 'Test Category',
              price: 9.99,
              quantity: 2,
            ),
          ],
          metadata: {'custom_key': 'custom_value'},
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => testIpInfo);
        // We need to allow any debugLog calls
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Act
        final result = await payloadService.createPayload(testEvent);

        // Assert
        verify(() => mockUserService.getUser()).called(1);
        verify(() => mockIPService.getIpInfo()).called(1);
        verify(() => mockLogger.debugLog(any())).called(1);

        expect(result, {
          'x-cf-ip': '1.2.3.4',
          'x-cf-loc': 'US',
          'event_source': 'mobile',
          'muid': 'test-muid',
          'sessionId': 'uuid-0',
          'msid': 'uuid-1',
          'email': 'test@example.com',
          'phone': '1234567890',
          'pageUrl': 'https://test.com/page',
          'event': 'TestEvent',
          'deviceId': null,
          'products': [
            {
              'id': 'test-id',
              'name': 'Test Product',
              'category': 'Test Category',
              'price': 9.99,
              'quantity': 2,
            },
          ],
          'custom_key': 'custom_value',
        });
      });

      test('creates payload without optional event data', () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        final testEvent = MarktagEvent(
          event: 'TestEvent',
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => testIpInfo);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Act
        final result = await payloadService.createPayload(testEvent);

        // Assert
        verify(() => mockUserService.getUser()).called(1);
        verify(() => mockIPService.getIpInfo()).called(1);
        verify(() => mockLogger.debugLog(any())).called(1);

        expect(result, {
          'x-cf-ip': '1.2.3.4',
          'x-cf-loc': 'US',
          'event_source': 'mobile',
          'muid': 'test-muid',
          'sessionId': 'uuid-0',
          'msid': 'uuid-1',
          'pageUrl': null,
          'event': 'TestEvent',
          'products': null,
          'deviceId': null,
        });
      });

      test('creates payload with items but no metadata', () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        final testEvent = MarktagEvent(
          event: 'TestEvent',
          items: [
            const MarktagEventItem(
              id: 'item-1',
            ),
          ],
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => testIpInfo);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Act
        final result = await payloadService.createPayload(testEvent);

        // Assert
        verify(() => mockUserService.getUser()).called(1);
        verify(() => mockIPService.getIpInfo()).called(1);
        verify(() => mockLogger.debugLog(any())).called(1);

        expect(result, {
          'x-cf-ip': '1.2.3.4',
          'x-cf-loc': 'US',
          'event_source': 'mobile',
          'muid': 'test-muid',
          'sessionId': 'uuid-0',
          'msid': 'uuid-1',
          'pageUrl': null,
          'event': 'TestEvent',
          'products': [
            {
              'id': 'item-1',
            },
          ],
          'deviceId': null,
        });
      });

      test('creates payload with metadata but no items', () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        final testEvent = MarktagEvent(
          event: 'TestEvent',
          metadata: {'key1': 'value1', 'key2': 42},
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => testIpInfo);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Act
        final result = await payloadService.createPayload(testEvent);

        // Assert
        verify(() => mockUserService.getUser()).called(1);
        verify(() => mockIPService.getIpInfo()).called(1);
        verify(() => mockLogger.debugLog(any())).called(1);

        expect(result, {
          'x-cf-ip': '1.2.3.4',
          'x-cf-loc': 'US',
          'event_source': 'mobile',
          'muid': 'test-muid',
          'sessionId': 'uuid-0',
          'msid': 'uuid-1',
          'pageUrl': null,
          'event': 'TestEvent',
          'products': null,
          'key1': 'value1',
          'key2': 42,
          'deviceId': null,
        });
      });

      test(
        'calls setUser when email or phone is provided in the event',
        () async {
          // Arrange
          const testUser = User(
            muid: 'test-muid',
            email: 'updated@example.com',
            phone: '9876543210',
          );
          final testIpInfo = IPInfo(
            ip: '1.2.3.4',
            loc: 'US',
            uag: 'test-agent',
          );
          final testEvent = MarktagEvent(
            event: 'TestEvent',
            email: 'updated@example.com',
            phone: '9876543210',
          );

          when(
            () => mockUserService.setUser(
              email: testEvent.email,
              phone: testEvent.phone,
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockUserService.getUser(),
          ).thenAnswer((_) async => testUser);
          when(
            () => mockIPService.getIpInfo(),
          ).thenAnswer((_) async => testIpInfo);
          when(() => mockLogger.debugLog(any())).thenReturn(null);

          // Act
          final result = await payloadService.createPayload(testEvent);

          // Assert
          verify(
            () => mockUserService.setUser(
              email: testEvent.email,
              phone: testEvent.phone,
            ),
          ).called(1);
          verify(() => mockUserService.getUser()).called(1);
          verify(() => mockIPService.getIpInfo()).called(1);
          verify(() => mockLogger.debugLog(any())).called(1);

          expect(result, {
            'x-cf-ip': '1.2.3.4',
            'x-cf-loc': 'US',
            'event_source': 'mobile',
            'muid': 'test-muid',
            'sessionId': 'uuid-0',
            'msid': 'uuid-1',
            'email': 'updated@example.com',
            'phone': '9876543210',
            'pageUrl': null,
            'event': 'TestEvent',
            'products': null,
            'deviceId': null,
          });
        },
      );

      test('does not call setUser when event has no email or phone', () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        final testEvent = MarktagEvent(
          event: 'TestEvent',
          // No email or phone provided
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => testIpInfo);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Act
        final result = await payloadService.createPayload(testEvent);

        // Assert
        verifyNever(
          () => mockUserService.setUser(
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        );
        verify(() => mockUserService.getUser()).called(1);
        verify(() => mockIPService.getIpInfo()).called(1);
        verify(() => mockLogger.debugLog(any())).called(1);

        expect(result, {
          'x-cf-ip': '1.2.3.4',
          'x-cf-loc': 'US',
          'event_source': 'mobile',
          'muid': 'test-muid',
          'sessionId': 'uuid-0',
          'msid': 'uuid-1',
          'pageUrl': null,
          'event': 'TestEvent',
          'products': null,
          'deviceId': null,
        });
      });

      test('propagates exceptions from userService', () async {
        // Arrange
        final testEvent = MarktagEvent(
          event: 'TestEvent',
        );
        final testException = Exception('User service error');

        when(() => mockUserService.getUser()).thenThrow(testException);

        // Act & Assert
        expect(
          () => payloadService.createPayload(testEvent),
          throwsA(equals(testException)),
        );
        verify(() => mockUserService.getUser()).called(1);
        verifyNever(() => mockIPService.getIpInfo());
        verifyNever(() => mockLogger.debugLog(any()));
      });
    });

    group('msid rotation', () {
      late DateTime currentTime;
      late PayloadService rotatingPayloadService;

      setUp(() {
        currentTime = DateTime(2026, 1, 1, 12);
        rotatingPayloadService = PayloadService(
          userService: mockUserService,
          ipService: mockIPService,
          logger: mockLogger,
          campaignAttributionService: mockCampaignAttributionService,
          resolveDeviceId: () async => null,
          uuidGenerator: mockUuid,
          now: () => currentTime,
        );

        when(
          () => mockUserService.getUser(),
        ).thenAnswer((_) async => const User(muid: 'test-muid'));
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => IPInfo(ip: '1.2.3.4', loc: 'US', uag: 'ua'));
        when(() => mockLogger.debugLog(any())).thenReturn(null);
      });

      test('stays the same for calls less than 30 minutes apart', () async {
        final event = MarktagEvent(event: 'TestEvent');
        final first = await rotatingPayloadService.createPayload(event);

        currentTime = currentTime.add(const Duration(minutes: 10));
        final second = await rotatingPayloadService.createPayload(event);

        expect(second['msid'], equals(first['msid']));
      });

      test('rotates after more than 30 minutes of inactivity', () async {
        final event = MarktagEvent(event: 'TestEvent');
        final first = await rotatingPayloadService.createPayload(event);

        currentTime = currentTime.add(const Duration(minutes: 31));
        final second = await rotatingPayloadService.createPayload(event);

        expect(second['msid'], isNot(equals(first['msid'])));
      });

      test('sessionId never changes regardless of msid rotation', () async {
        final event = MarktagEvent(event: 'TestEvent');
        final first = await rotatingPayloadService.createPayload(event);

        currentTime = currentTime.add(const Duration(minutes: 31));
        final second = await rotatingPayloadService.createPayload(event);

        currentTime = currentTime.add(const Duration(minutes: 5));
        final third = await rotatingPayloadService.createPayload(event);

        expect(first['sessionId'], equals(second['sessionId']));
        expect(second['sessionId'], equals(third['sessionId']));
      });

      test(
        'first call in a fresh instance does not spuriously rotate',
        () async {
          final event = MarktagEvent(event: 'TestEvent');
          final result = await rotatingPayloadService.createPayload(event);

          // The msid minted at construction time is what's sent — the
          // first event never sees a rotation, since there's no prior
          // event to compare against.
          expect(result['msid'], equals(rotatingPayloadService.currentMsid));
        },
      );
    });

    group('attribution merge', () {
      setUp(() {
        when(
          () => mockUserService.getUser(),
        ).thenAnswer((_) async => const User(muid: 'test-muid'));
        when(
          () => mockIPService.getIpInfo(),
        ).thenAnswer((_) async => IPInfo(ip: '1.2.3.4', loc: 'US', uag: 'ua'));
        when(() => mockLogger.debugLog(any())).thenReturn(null);
      });

      test('merges an active context with is_same_session true', () async {
        final now = DateTime(2026, 1, 10, 12);
        final capturedAt = now.subtract(const Duration(minutes: 5));
        final localPayloadService = PayloadService(
          userService: mockUserService,
          ipService: mockIPService,
          logger: mockLogger,
          campaignAttributionService: mockCampaignAttributionService,
          resolveDeviceId: () async => null,
          uuidGenerator: mockUuid,
          now: () => now,
        );
        final context = CampaignContext(
          campaignId: 'camp_789',
          contentId: 'content_abc',
          nodeId: 'node_1',
          capturedAtMs: capturedAt.millisecondsSinceEpoch,
          msid: localPayloadService.currentMsid,
        );
        when(
          () => mockCampaignAttributionService.getActiveContext(),
        ).thenAnswer((_) async => context);

        final result = await localPayloadService.createPayload(
          MarktagEvent(event: 'Purchase'),
        );

        expect(result['attribution'], {
          'utm': {
            'utm_campaign': 'camp_789',
            'utm_medium': 'push',
            'utm_source': 'markopolo',
            'utm_content': 'content_abc',
            'utm_node': 'node_1',
          },
          'is_same_session': true,
          'minutes_since_click': 5,
          'days_since_click': 0,
        });
      });

      test('is_same_session is false when stored msid differs', () async {
        final now = DateTime(2026, 1, 10, 12);
        final capturedAt = now.subtract(const Duration(days: 3));
        final context = CampaignContext(
          campaignId: 'camp_789',
          contentId: 'content_abc',
          nodeId: 'node_1',
          capturedAtMs: capturedAt.millisecondsSinceEpoch,
          msid: 'a-different-msid',
        );
        when(
          () => mockCampaignAttributionService.getActiveContext(),
        ).thenAnswer((_) async => context);
        final localPayloadService = PayloadService(
          userService: mockUserService,
          ipService: mockIPService,
          logger: mockLogger,
          campaignAttributionService: mockCampaignAttributionService,
          resolveDeviceId: () async => null,
          uuidGenerator: mockUuid,
          now: () => now,
        );

        final result = await localPayloadService.createPayload(
          MarktagEvent(event: 'Purchase'),
        );

        final attribution = result['attribution'] as Map<String, dynamic>;
        expect(attribution['is_same_session'], isFalse);
        expect(attribution['days_since_click'], 3);
      });

      test(
        'omits the attribution key entirely when there is no active context',
        () async {
          when(
            () => mockCampaignAttributionService.getActiveContext(),
          ).thenAnswer((_) async => null);

          final result = await payloadService.createPayload(
            MarktagEvent(event: 'TestEvent'),
          );

          expect(result.containsKey('attribution'), isFalse);
        },
      );

      test(
        'omits the attribution key and still returns a payload when '
        'getActiveContext throws',
        () async {
          when(
            () => mockCampaignAttributionService.getActiveContext(),
          ).thenThrow(Exception('storage failure'));

          final result = await payloadService.createPayload(
            MarktagEvent(event: 'TestEvent'),
          );

          expect(result.containsKey('attribution'), isFalse);
          expect(result['event'], 'TestEvent');
        },
      );
    });
  });
}
