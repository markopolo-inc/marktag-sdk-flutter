import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late EventService eventService;
  late MockHttpClient mockHttpClient;
  late MockLoggerService mockLogger;

  const testTag = 'test-tag.marktag.com';
  final testPayload = {'event': 'test_event', 'data': 'test_data'};
  final testResponseBody = {'status': 'success', 'id': '12345'};

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://$testTag/mark'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLogger = MockLoggerService();

    eventService = EventService(
      tag: testTag,
      logger: mockLogger,
      httpClient: mockHttpClient,
    );
  });

  group('EventService', () {
    test('constructor initializes properties correctly', () {
      expect(eventService.tag, equals(testTag));
      expect(eventService.logger, isA<LoggerService>());
    });

    group('markEvent', () {
      test('successfully sends event and returns response', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode(testResponseBody),
            201,
          ),
        );
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        final result = await eventService.markEvent(testPayload);

        verify(
          () => mockHttpClient.post(
            Uri.parse('https://$testTag/mark'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(testPayload),
          ),
        ).called(1);

        verify(() => mockLogger.debugLog(any())).called(2);

        expect(result, equals(testResponseBody));
      });

      test('throws Exception when response status code is not 201', () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"error": "Bad Request"}', 400),
        );
        when(
          () => mockLogger.debugLog(any(), error: any(named: 'error')),
        ).thenReturn(null);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        await expectLater(
          () => eventService.markEvent(testPayload),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to send event. Status code: 400'),
            ),
          ),
        );

        verify(
          () => mockLogger.debugLog(
            'Error sending event: {"error": "Bad Request"}',
          ),
        ).called(1);
      });

      test('rethrows exceptions that occur during request', () async {
        final testException = Exception('Network error');
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(testException);
        when(
          () => mockLogger.debugLog(any(), error: any(named: 'error')),
        ).thenReturn(null);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        await expectLater(
          () => eventService.markEvent(testPayload),
          throwsA(testException),
        );

        verify(
          () => mockLogger.debugLog(any(), error: testException),
        ).called(1);
      });
    });
  });
}
