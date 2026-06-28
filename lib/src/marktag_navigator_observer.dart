import 'dart:async';

import 'package:flutter/material.dart';
import 'package:marktag/src/marktag.dart';
import 'package:marktag/src/services/logger_service.dart';

/// Signature for a function that extracts a screen name from [RouteSettings].
///
/// This allows customization of how screen names are determined from routes.
typedef ScreenNameExtractor = String? Function(RouteSettings settings);

/// Default implementation of [ScreenNameExtractor] that returns the route name.
String? defaultNameExtractor(RouteSettings settings) => settings.name;

/// [RouteFilter] allows filtering out routes that should not be tracked.
///
/// By default, only [PageRoute]s are tracked.
typedef RouteFilter = bool Function(Route<dynamic>? route);

/// Default implementation of [RouteFilter] that only tracks [PageRoute]s.
bool defaultRouteFilter(Route<dynamic>? route) => route is PageRoute;

/// A [NavigatorObserver] that automatically logs page views to Marktag.
///
/// Add this observer to your MaterialApp's navigatorObservers to automatically
/// track page navigation events:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [MarktagNavigatorObserver()],
///   // ...
/// )
/// ```
///
/// You can customize how screen names are extracted from routes by providing a
/// custom [nameExtractor], and can filter which routes
/// are tracked with [routeFilter].
///
/// The following navigation operations will trigger screen view tracking:
/// - Push: When a new route is pushed onto the navigator
/// - Replace: When a route is replaced with another route
/// - Pop: When returning to a previous route
///
/// This observer can also be used with RouteAware for more granular tracking.
class MarktagNavigatorObserver extends RouteObserver<ModalRoute<dynamic>> {
  /// Creates a [MarktagNavigatorObserver] instance.
  ///
  /// - logger: Optional custom logger,
  /// defaults to LoggerService with name 'MarktagNavigatorObserver'
  /// - [nameExtractor]: Function to extract screen names from routes,
  /// defaults to using route.settings.name
  /// - [routeFilter]: Function to determine which routes should be tracked,
  /// defaults to only tracking PageRoutes
  /// - [onError]: Optional callback for handling errors during tracking
  MarktagNavigatorObserver({
    required this.marktag,
    this.nameExtractor = defaultNameExtractor,
    this.routeFilter = defaultRouteFilter,
    void Function(Exception error)? onError,
  }) : _onError = onError;

  /// The [Marktag] instance to use for logging.
  final Marktag marktag;

  /// Function to extract screen names from routes.
  final ScreenNameExtractor nameExtractor;

  /// Function to determine which routes should be tracked.
  final RouteFilter routeFilter;

  /// Optional callback for handling errors during tracking.
  final void Function(Exception error)? _onError;

  /// Logs a page view to Marktag.
  void _logPageView(Route<dynamic> route) {
    final logger = LoggerService(
      name: 'MarktagNavigatorObserver',
      enabled: marktag.loggerService?.enabled ?? false,
    );
    try {
      final screenName = nameExtractor(route.settings);
      if (screenName != null && screenName.isNotEmpty) {
        logger.debugLog('Navigated to: $screenName');
        unawaited(marktag.logPageView(screenName));
      }
    } on Exception catch (error) {
      if (_onError != null) {
        _onError(error);
      } else {
        logger.debugLog('Error logging page view: $error', error: error);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (routeFilter(route)) {
      _logPageView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && routeFilter(newRoute)) {
      _logPageView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null && routeFilter(previousRoute)) {
      _logPageView(previousRoute);
    }
  }
}
