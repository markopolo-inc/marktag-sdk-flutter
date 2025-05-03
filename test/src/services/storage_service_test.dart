import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  group('StorageService with mocks', () {
    late MockSharedPreferences mockPrefs;
    late MockLoggerService mockLogger;
    late StorageService storageService;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockLogger = MockLoggerService();
      storageService = StorageService(
        sharedPreferences: mockPrefs,
        logger: mockLogger,
      );
    });

    const testKey = 'testKey';
    const testValue = 'testValue';

    test('setString stores value and logs', () async {
      when(() => mockPrefs.setString(testKey, testValue))
          .thenAnswer((_) async => true);
      when(() => mockLogger.debugLog(any())).thenReturn(null);
      final result = await storageService.setString(testKey, testValue);
      expect(result, isTrue);
      verify(() => mockPrefs.setString(testKey, testValue)).called(1);
      verify(() => mockLogger.debugLog(any())).called(1);
    });

    test('getString retrieves value and logs', () async {
      when(() => mockPrefs.getString(testKey)).thenReturn(testValue);
      when(() => mockLogger.debugLog(any())).thenReturn(null);
      final result = await storageService.getString(testKey);
      expect(result, testValue);
      verify(() => mockPrefs.getString(testKey)).called(1);
      verify(() => mockLogger.debugLog(any())).called(1);
    });

    test('remove deletes value and logs', () async {
      when(() => mockPrefs.remove(testKey)).thenAnswer((_) async => true);
      when(() => mockLogger.debugLog(any())).thenReturn(null);
      final result = await storageService.remove(testKey);
      expect(result, isTrue);
      verify(() => mockPrefs.remove(testKey)).called(1);
      verify(() => mockLogger.debugLog(any())).called(1);
    });

    test('clear clears all values and logs', () async {
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);
      when(() => mockLogger.debugLog(any())).thenReturn(null);
      final result = await storageService.clear();
      expect(result, isTrue);
      verify(() => mockPrefs.clear()).called(1);
      verify(() => mockLogger.debugLog(any())).called(1);
    });
  });

  group('StorageService with default constructor', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('creates service with default logger when none provided', () {
      // Just verifying that constructor doesn't throw an exception
      expect(() => StorageService(sharedPreferences: MockSharedPreferences()),
          returnsNormally);
    });

    test('uses SharedPreferences.getInstance() when no instance provided',
        () async {
      // Setup mock shared preferences
      SharedPreferences.setMockInitialValues({'testKey': 'testValue'});

      // Create service with default SharedPreferences
      storageService = StorageService(logger: MockLoggerService());

      // Test that the service can retrieve values, proving it's using SharedPreferences
      final result = await storageService.getString('testKey');
      expect(result, 'testValue');
    });

    test('full integration with default implementations', () async {
      // Setup mock shared preferences
      SharedPreferences.setMockInitialValues({});

      // Create service with all defaults
      storageService = StorageService();

      // Test the full flow
      await storageService.setString('testKey', 'testValue');
      final result = await storageService.getString('testKey');
      expect(result, 'testValue');

      await storageService.remove('testKey');
      final removedResult = await storageService.getString('testKey');
      expect(removedResult, null);
    });
  });
}
