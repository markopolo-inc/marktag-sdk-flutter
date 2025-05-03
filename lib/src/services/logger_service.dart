import 'dart:developer';

/// A service for logging messages.
class LoggerService {
  /// Creates a [LoggerService] instance.
  const LoggerService({required this.name});

  /// A static field to enable or disable logging.
  static bool enabled = true;

  /// The name of the logger.
  final String name;

  /// Logs a message if logging is enabled.
  void debugLog(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    log(
      message,
      time: time,
      sequenceNumber: sequenceNumber,
      level: level,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
