import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/marktag.dart';
import 'package:marktag/src/marktag_navigator_observer.dart';
import 'package:mocktail/mocktail.dart';

class MockMarktag extends Mock implements Marktag {}

class MockRoute extends Mock implements Route<dynamic> {}

class MockRouteSettings extends Mock implements RouteSettings {}

class MockPageRoute extends Mock implements PageRoute<dynamic> {}

void main() {
  group('MarktagNavigatorObserver', () {
    late MockMarktag mockMarktag;
    late MockRoute mockRoute;
    late MockPageRoute mockPageRoute;
    late MockRouteSettings mockRouteSettings;
    late MarktagNavigatorObserver observer;

    setUp(() {
      mockMarktag = MockMarktag();
      mockRoute = MockRoute();
      mockPageRoute = MockPageRoute();
      mockRouteSettings = MockRouteSettings();

      // Setup default route settings
      when(() => mockRouteSettings.name).thenReturn('test_route');
      when(() => mockRoute.settings).thenReturn(mockRouteSettings);
      when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);

      // Setup default Marktag behavior
      when(() => mockMarktag.logPageView(any())).thenAnswer((_) async {});

      // Create the observer with default settings
      observer = MarktagNavigatorObserver(marktag: mockMarktag);
    });

    tearDown(() {});

    test('constructor sets default extractors and filters correctly', () {
      expect(observer.nameExtractor, equals(defaultNameExtractor));
      expect(observer.routeFilter, equals(defaultRouteFilter));
      expect(observer.marktag, equals(mockMarktag));
    });

    group('defaultNameExtractor', () {
      test('returns the route name from settings', () {
        when(() => mockRouteSettings.name).thenReturn('test_name');

        final result = defaultNameExtractor(mockRouteSettings);

        expect(result, equals('test_name'));
      });

      test('returns null when settings name is null', () {
        when(() => mockRouteSettings.name).thenReturn(null);

        final result = defaultNameExtractor(mockRouteSettings);

        expect(result, isNull);
      });
    });

    group('defaultRouteFilter', () {
      test('returns true for PageRoute', () {
        final result = defaultRouteFilter(mockPageRoute);

        expect(result, isTrue);
      });

      test('returns false for non-PageRoute', () {
        final result = defaultRouteFilter(mockRoute);

        expect(result, isFalse);
      });

      test('returns false for null route', () {
        final result = defaultRouteFilter(null);

        expect(result, isFalse);
      });
    });

    group('didPush', () {
      test('logs page view when route passes filter', () {
        // Setup
        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('pushed_route');

        // Execute
        observer.didPush(mockPageRoute, null);

        // Verify
        verify(() => mockMarktag.logPageView('pushed_route')).called(1);
      });

      test('does not log page view when route fails filter', () {
        // Setup - regular route, not a PageRoute
        when(() => mockRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('filtered_route');

        // Execute
        observer.didPush(mockRoute, null);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });

      test('does not log page view when route name is null', () {
        // Setup
        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn(null);

        // Execute
        observer.didPush(mockPageRoute, null);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });

      test('does not log page view when route name is empty', () {
        // Setup
        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('');

        // Execute
        observer.didPush(mockPageRoute, null);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });
    });

    group('didReplace', () {
      test('logs page view when new route passes filter', () {
        // Setup
        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('replaced_route');

        // Execute
        observer.didReplace(newRoute: mockPageRoute, oldRoute: mockRoute);

        // Verify
        verify(() => mockMarktag.logPageView('replaced_route')).called(1);
      });

      test('does not log page view when new route fails filter', () {
        // Execute - with regular route that's not a PageRoute
        observer.didReplace(newRoute: mockRoute, oldRoute: mockPageRoute);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });

      test('does not log page view when new route is null', () {
        // Execute
        observer.didReplace(oldRoute: mockPageRoute);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });
    });

    group('didPop', () {
      test('logs page view for previous route when it passes filter', () {
        // Setup
        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('previous_route');

        // Execute
        observer.didPop(mockRoute, mockPageRoute);

        // Verify
        verify(() => mockMarktag.logPageView('previous_route')).called(1);
      });

      test('does not log page view when previous route fails filter', () {
        // Execute - popping to a regular route that's not a PageRoute
        observer.didPop(mockPageRoute, mockRoute);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });

      test('does not log page view when previous route is null', () {
        // Execute
        observer.didPop(mockPageRoute, null);

        // Verify
        verifyNever(() => mockMarktag.logPageView(any()));
      });
    });

    group('custom nameExtractor', () {
      test('uses custom nameExtractor when provided', () {
        // Setup custom extractor that prepends "Screen: " to route names
        String? customNameExtractor(RouteSettings settings) =>
            settings.name != null ? 'Screen: ${settings.name}' : null;

        final customObserver = MarktagNavigatorObserver(
          marktag: mockMarktag,
          nameExtractor: customNameExtractor,
        );

        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('custom_route');

        // Execute
        customObserver.didPush(mockPageRoute, null);

        // Verify
        verify(() => mockMarktag.logPageView('Screen: custom_route')).called(1);
      });
    });

    group('custom routeFilter', () {
      test('uses custom routeFilter when provided', () {
        // Setup custom filter that always returns true
        bool customRouteFilter(Route<dynamic>? route) => true;

        final customObserver = MarktagNavigatorObserver(
          marktag: mockMarktag,
          routeFilter: customRouteFilter,
        );

        when(() => mockRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('filtered_route');

        // Execute - with a regular route that would normally be filtered out
        customObserver.didPush(mockRoute, null);

        // Verify
        verify(() => mockMarktag.logPageView('filtered_route')).called(1);
      });
    });

    group('error handling', () {
      test('catches exceptions during page view logging', () {
        // Setup
        final errors = <Exception>[];

        final errorObserver = MarktagNavigatorObserver(
          marktag: mockMarktag,
          onError: errors.add,
        );

        when(() => mockPageRoute.settings).thenReturn(mockRouteSettings);
        when(() => mockRouteSettings.name).thenReturn('error_route');
        when(
          () => mockMarktag.logPageView(any()),
        ).thenThrow(Exception('Test error'));

        // Execute
        errorObserver.didPush(mockPageRoute, null);

        // Verify
        expect(errors.length, 1);
        expect(errors.first.toString(), contains('Test error'));
      });
    });
  });
}
