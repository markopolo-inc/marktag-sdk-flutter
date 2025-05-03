import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late EventService eventService;
  late MockHttpClient mockHttpClient;
  late MockHttpClientRequest mockRequest;
  late MockHttpClientResponse mockResponse;
  late MockHttpHeaders mockHeaders;
  late MockLoggerService mockLogger;

  const testTag = 'test-tag.marktag.com';
  final testPayload = {'event': 'test_event', 'data': 'test_data'};
  final testResponseBody = {'status': 'success', 'id': '12345'};

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockRequest = MockHttpClientRequest();
    mockResponse = MockHttpClientResponse();
    mockHeaders = MockHttpHeaders();
    mockLogger = MockLoggerService();

    eventService = EventService(
      tag: testTag,
      logger: mockLogger,
    );

    // Register fallback values
    registerFallbackValue(Uri.parse('https://$testTag/mark'));
  });

  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('EventService', () {
    test('constructor initializes properties correctly', () {
      expect(eventService.tag, equals(testTag));
      expect(eventService.logger, isA<LoggerService>());
    });

    group('markEvent', () {
      test('successfully sends event and returns response', () async {
        // Arrange - Setup mocks
        when(() => mockHttpClient.postUrl(any()))
            .thenAnswer((_) async => mockRequest);
        when(() => mockRequest.headers).thenReturn(mockHeaders);
        when(() => mockHeaders.set(any(), any())).thenReturn(null);
        when(() => mockRequest.write(any())).thenReturn(null);
        when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
        when(() => mockResponse.statusCode).thenReturn(201);
        when(
          () => mockResponse.listen(
            any(),
            onDone: any(named: 'onDone'),
            onError: any(named: 'onError'),
            cancelOnError: any(named: 'cancelOnError'),
          ),
        ).thenAnswer((invocation) {
          final onData =
              invocation.positionalArguments[0] as void Function(List<int>);
          final onDone = invocation.namedArguments[#onDone] as void Function();

          // Add the response data
          onData(utf8.encode(jsonEncode(testResponseBody)));
          onDone();

          return const Stream<List<int>>.empty().listen((_) {});
        });
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Override HttpClient creation
        HttpOverrides.global = _MockHttpOverrides(mockHttpClient);

        // Act
        final result = await eventService.markEvent(testPayload);

        // Assert
        verify(() => mockHttpClient.postUrl(Uri.parse('https://$testTag/mark')))
            .called(1);
        verify(() => mockHeaders.set('Content-Type', 'application/json'))
            .called(1);
        verify(() => mockRequest.write(jsonEncode(testPayload))).called(1);
        verify(() => mockRequest.close()).called(1);

        // Verify logger calls
        verify(() => mockLogger.debugLog(any()))
            .called(2); // Log at start and success

        expect(result, equals(testResponseBody));
      });

      test('throws HttpException when response status code is not 200',
          () async {
        // Arrange - Setup mocks
        when(() => mockHttpClient.postUrl(any()))
            .thenAnswer((_) async => mockRequest);
        when(() => mockRequest.headers).thenReturn(mockHeaders);
        when(() => mockHeaders.set(any(), any())).thenReturn(null);
        when(() => mockRequest.write(any())).thenReturn(null);
        when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
        when(() => mockResponse.statusCode).thenReturn(400);
        when(
          () => mockResponse.listen(
            any(),
            onDone: any(named: 'onDone'),
            onError: any(named: 'onError'),
            cancelOnError: any(named: 'cancelOnError'),
          ),
        ).thenAnswer((invocation) {
          final onData =
              invocation.positionalArguments[0] as void Function(List<int>);
          final onDone = invocation.namedArguments[#onDone] as void Function();

          // Add the error response data
          onData(utf8.encode('{"error": "Bad Request"}'));
          onDone();

          return const Stream<List<int>>.empty().listen((_) {});
        });
        when(() => mockLogger.debugLog(any(), error: any(named: 'error')))
            .thenReturn(null);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Override HttpClient creation
        HttpOverrides.global = _MockHttpOverrides(mockHttpClient);

        // Act & Assert
        await expectLater(
          () => eventService.markEvent(testPayload),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              'Failed to send event. Status code: 400',
            ),
          ),
        );

        // Verify
        verify(
          () => mockLogger.debugLog(
            'Error sending event: {"error": "Bad Request"}',
          ),
        ).called(1);
      });

      test('rethrows exceptions that occur during request', () async {
        // Arrange - Setup mocks
        final testException = Exception('Network error');
        when(() => mockHttpClient.postUrl(any())).thenThrow(testException);
        when(() => mockLogger.debugLog(any(), error: any(named: 'error')))
            .thenReturn(null);
        when(() => mockLogger.debugLog(any())).thenReturn(null);

        // Override HttpClient creation
        HttpOverrides.global = _MockHttpOverrides(mockHttpClient);

        // Act & Assert
        await expectLater(
          () => eventService.markEvent(testPayload),
          throwsA(testException),
        );

        // Verify
        verify(() => mockLogger.debugLog(any(), error: testException))
            .called(1);
      });
    });
  });
}

class _MockHttpOverrides extends HttpOverrides {
  _MockHttpOverrides(this._mockHttpClient);
  final HttpClient _mockHttpClient;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _mockHttpClient;
  }
}
