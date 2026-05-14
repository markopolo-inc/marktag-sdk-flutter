import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:marktag/src/services/ip_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
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
    late IPService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = IPService(httpClient: mockHttpClient);
      IPService.resetCache();
    });

    group('constructor', () {
      test('uses provided http.Client when specified', () async {
        final customClient = MockHttpClient();
        final customService = IPService(httpClient: customClient);
        when(() => customClient.get(any())).thenAnswer(
          (_) async => http.Response(
            'ip=1.1.1.1\nloc=US\nuag=test\n',
            200,
          ),
        );

        await customService.getIpInfo();

        verify(() => customClient.get(any())).called(1);
      });

      test('creates new http.Client when not specified', () {
        expect(IPService.new, returnsNormally);
      });
    });

    test('returns IPInfo on valid response', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\nuag=agent\n';
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(responseString, 200),
      );

      final info = await service.getIpInfo();
      expect(info.ip, '1.2.3.4');
      expect(info.loc, 'US');
      expect(info.uag, 'agent');
    });

    test('throws StateError on non-200 response', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('', 404),
      );

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('throws StateError on empty response', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('', 200),
      );

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('throws StateError on missing fields', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\n';
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(responseString, 200),
      );

      expect(() => service.getIpInfo(), throwsA(isA<StateError>()));
    });

    test('returns cached IPInfo on subsequent calls', () async {
      const responseString = 'ip=1.2.3.4\nloc=US\nuag=agent\n';
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(responseString, 200),
      );

      final info1 = await service.getIpInfo();
      final info2 = await service.getIpInfo();
      expect(identical(info1, info2), isTrue);
      verify(() => mockHttpClient.get(any())).called(1);
    });
  });
}
