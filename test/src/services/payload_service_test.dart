import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/models/user.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/services/user_service.dart';
import 'package:mocktail/mocktail.dart';

class MockUserService extends Mock implements UserService {}

class MockIPService extends Mock implements IPService {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late PayloadService payloadService;
  late MockUserService mockUserService;
  late MockIPService mockIPService;
  late MockLoggerService mockLogger;

  setUp(() {
    mockUserService = MockUserService();
    mockIPService = MockIPService();
    mockLogger = MockLoggerService();
    payloadService = PayloadService(
      userService: mockUserService,
      ipService: mockIPService,
      logger: mockLogger,
      resolveDeviceId: () async => null,
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
        const testEvent = MarktagEvent(
          event: 'test_event',
          pageUrl: 'https://test.com/page',
          items: [
            MarktagEventItem(
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
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'email': 'test@example.com',
          'phone': '1234567890',
          'pageUrl': 'https://test.com/page',
          'event': 'test_event',
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
        const testEvent = MarktagEvent(
          event: 'test_event',
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'pageUrl': null,
          'event': 'test_event',
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
        const testEvent = MarktagEvent(
          event: 'test_event',
          items: [
            MarktagEventItem(
              id: 'item-1',
            ),
          ],
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'pageUrl': null,
          'event': 'test_event',
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
        const testEvent = MarktagEvent(
          event: 'test_event',
          metadata: {'key1': 'value1', 'key2': 42},
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'pageUrl': null,
          'event': 'test_event',
          'products': null,
          'key1': 'value1',
          'key2': 42,
          'deviceId': null,
        });
      });

      test('calls setUser when email or phone is provided in the event',
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
        const testEvent = MarktagEvent(
          event: 'test_event',
          email: 'updated@example.com',
          phone: '9876543210',
        );

        when(
          () => mockUserService.setUser(
            email: testEvent.email,
            phone: testEvent.phone,
          ),
        ).thenAnswer((_) async {});
        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'email': 'updated@example.com',
          'phone': '9876543210',
          'pageUrl': null,
          'event': 'test_event',
          'products': null,
          'deviceId': null,
        });
      });

      test(
        'does not call setUser when event has no email or phone',
        () async {
        // Arrange
        const testUser = User(
          muid: 'test-muid',
        );
        final testIpInfo = IPInfo(
          ip: '1.2.3.4',
          loc: 'US',
          uag: 'test-agent',
        );
        const testEvent = MarktagEvent(
          event: 'test_event',
          // No email or phone provided
        );

        when(() => mockUserService.getUser()).thenAnswer((_) async => testUser);
        when(() => mockIPService.getIpInfo())
            .thenAnswer((_) async => testIpInfo);
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
          'pageUrl': null,
          'event': 'test_event',
          'products': null,
          'deviceId': null,
        });
      });

      test('propagates exceptions from userService', () async {
        // Arrange
        const testEvent = MarktagEvent(
          event: 'test_event',
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
  });
}
