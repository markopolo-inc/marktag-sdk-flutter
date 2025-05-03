import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('parseResponse', () {
    test('parses key-value pairs correctly', () {
      const response = 'ip=1.2.3.4\nloc=US\nuag=agent\n';
      final result = parseResponse(response);
      expect(result, {'ip': '1.2.3.4', 'loc': 'US', 'uag': 'agent'});
    });

    test('returns empty map for empty string', () {
      final result = parseResponse('');
      expect(result, <String, String>{});
    });

    test('ignores lines without =', () {
      const response = 'ip=1.2.3.4\ninvalidline\nloc=US\n';
      final result = parseResponse(response);
      expect(result, {'ip': '1.2.3.4', 'loc': 'US'});
    });
  });

  group('IPService', () {
    late MockHttpClient mockHttpClient;
    late MockHttpClientRequest mockRequest;
    late MockHttpClientResponse mockResponse;
    late IPService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockRequest = MockHttpClientRequest();
      mockResponse = MockHttpClientResponse();
      service = IPService(httpClient: mockHttpClient);
      // Reset static cache before each test
      IPService.resetCache();
    });

    test('returns IPInfo on valid response', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\nuag=agent\n';
      final responseStream = Stream<List<int>>.fromIterable([
        utf8.encode(responseString),
      ]);
      when(() => mockHttpClient.getUrl(any()))
          .thenAnswer((_) async => mockRequest);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.transform(utf8.decoder))
          .thenAnswer((_) => responseStream.transform(utf8.decoder));

      final info = await service.getIpInfo();
      expect(info.ip, '1.2.3.4');
      expect(info.loc, 'US');
      expect(info.uag, 'agent');
    });

    test('throws StateError on non-200 response', () async {
      when(() => mockHttpClient.getUrl(any()))
          .thenAnswer((_) async => mockRequest);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.transform(utf8.decoder)).thenAnswer(
        (_) => const Stream<List<int>>.empty().transform(utf8.decoder),
      );

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('throws StateError on empty response', () async {
      when(() => mockHttpClient.getUrl(any()))
          .thenAnswer((_) async => mockRequest);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.transform(utf8.decoder)).thenAnswer(
        (_) => Stream<List<int>>.fromIterable([utf8.encode('')])
            .transform(utf8.decoder),
      );

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('throws StateError on missing fields', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\n'; // missing uag
      final responseStream = Stream<List<int>>.fromIterable([
        utf8.encode(responseString),
      ]);
      when(() => mockHttpClient.getUrl(any()))
          .thenAnswer((_) async => mockRequest);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.transform(utf8.decoder))
          .thenAnswer((_) => responseStream.transform(utf8.decoder));

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('returns cached IPInfo on subsequent calls', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\nuag=agent\n';
      final responseStream = Stream<List<int>>.fromIterable([
        utf8.encode(responseString),
      ]);
      when(() => mockHttpClient.getUrl(any()))
          .thenAnswer((_) async => mockRequest);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.transform(utf8.decoder))
          .thenAnswer((_) => responseStream.transform(utf8.decoder));

      final info1 = await service.getIpInfo();
      final info2 = await service.getIpInfo();
      expect(identical(info1, info2), isTrue);
      verify(() => mockHttpClient.getUrl(any())).called(1);
    });
  });
}
