import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/user.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:marktag/src/services/user_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockStorageService extends Mock implements StorageService {}

class MockLoggerService extends Mock implements LoggerService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late MockStorageService storage;
  late MockLoggerService logger;
  late MockUuid uuid;
  late UserService userService;

  setUp(() {
    storage = MockStorageService();
    logger = MockLoggerService();
    uuid = MockUuid();
    userService = UserService(
      storageService: storage,
      logger: logger,
      uuidGenerator: uuid,
    );
  });

  group('UserService', () {
    const userKey = 'mt_user';
    const testMuid = 'test-muid';
    const testEmail = 'test@example.com';
    const testPhone = '1234567890';
    const testUser = User(muid: testMuid, email: testEmail, phone: testPhone);
    const testUserJson =
        '{"muid":"$testMuid","email":"$testEmail","phone":"$testPhone"}';

    test('getUser returns user from storage', () async {
      UserService.clearCache();
      when(() => storage.getString(userKey))
          .thenAnswer((_) async => testUserJson);
      final user = await userService.getUser();
      expect(user, testUser);
      verify(() => logger.debugLog(any())).called(1);
    });

    test('getUser returns cached user if already set', () async {
      UserService.testUser = testUser;
      final user = await userService.getUser();
      expect(user, testUser);
      verifyNever(() => storage.getString(any()));
      // No new log should be made for storage fetch
    });

    test('getUser creates and stores new user if not found', () async {
      UserService.clearCache();
      when(() => storage.getString(userKey)).thenAnswer((_) async => null);
      when(() => uuid.v4()).thenReturn(testMuid);
      when(() => storage.setString(userKey, any()))
          .thenAnswer((_) async => true);
      final user = await userService.getUser();
      expect(user.muid, testMuid);
      expect(user.email, isNull);
      expect(user.phone, isNull);
      verify(() => storage.setString(userKey, any())).called(1);
      verify(() => logger.debugLog(any())).called(1);
    });

    test('setUser updates existing user', () async {
      UserService.clearCache();
      when(() => storage.getString(userKey))
          .thenAnswer((_) async => '{"muid":"$testMuid"}');
      when(() => storage.setString(userKey, any()))
          .thenAnswer((_) async => true);
      await userService.setUser(email: testEmail, phone: testPhone);
      verify(() => storage.setString(userKey, any())).called(1);
      final logCalls = verify(() => logger.debugLog(captureAny())).captured;
      expect(
        logCalls.any((msg) => msg.toString().startsWith('User updated')),
        isTrue,
      );
    });

    test('setUser creates new user if not found', () async {
      UserService.clearCache();
      when(() => storage.getString(userKey)).thenAnswer((_) async => null);
      when(() => uuid.v4()).thenReturn(testMuid);
      when(() => storage.setString(userKey, any()))
          .thenAnswer((_) async => true);
      await userService.setUser(email: testEmail, phone: testPhone);
      verify(() => storage.setString(userKey, any())).called(1);
      final logCalls = verify(() => logger.debugLog(captureAny())).captured;
      expect(
        logCalls.any((msg) => msg.toString().startsWith('User updated')),
        isTrue,
      );
    });

    test('getUser logs and rethrows errors', () async {
      UserService.clearCache();
      when(() => storage.getString(userKey)).thenThrow(Exception('fail'));
      expect(() => userService.getUser(), throwsException);
      final logCalls = verify(
        () => logger.debugLog(
          captureAny(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).captured;
      expect(
        logCalls.any((msg) => msg.toString().startsWith('Error in getUser:')),
        isTrue,
      );
    });

    test('setUser logs and rethrows errors', () async {
      when(() => storage.getString(userKey)).thenThrow(Exception('fail'));
      expect(() => userService.setUser(email: testEmail), throwsException);
      final logCalls = verify(
        () => logger.debugLog(
          captureAny(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).captured;
      expect(
        logCalls.any((msg) => msg.toString().startsWith('Error in setUser:')),
        isTrue,
      );
    });
  });
}
