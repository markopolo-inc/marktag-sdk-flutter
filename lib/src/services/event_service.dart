import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:marktag/src/services/logger_service.dart';

/// A service responsible for sending events to the MarkTag server.
class EventService {
  /// Creates an instance of [EventService].
  ///
  /// Requires a [tag] parameter that specifies the MarkTag server endpoint.
  /// Optionally accepts a [LoggerService] for logging.
  EventService({
    required this.tag,
    LoggerService? logger,
  }) : logger = logger ?? LoggerService(name: 'EventService');

  /// The MarkTag server tag/domain.
  final String tag;

  /// The logger used for logging messages.
  final LoggerService logger;

  /// Sends an event payload to the MarkTag server.
  ///
  /// Takes a [payload] containing the event data and sends it to the server.
  /// Returns a [Future] that completes with the server response as a [Map].
  ///
  /// Throws [HttpException] if the request fails.
  Future<Map<String, dynamic>> markEvent(Map<String, dynamic> payload) async {
    logger.debugLog('Sending event to $tag with payload: $payload');

    final url = Uri.parse('https://$tag/mark');
    final httpClient = HttpClient();

    try {
      final request = await httpClient.postUrl(url);
      request.headers.set('Content-Type', 'application/json');

      final jsonPayload = jsonEncode(payload);
      request.write(jsonPayload);

      final response = await request.close();

      // Collect the response data
      final responseBody = await _readResponseAsString(response);

      if (response.statusCode != 201) {
        logger.debugLog('Error sending event: $responseBody');
        throw HttpException(
          'Failed to send event. Status code: ${response.statusCode}',
        );
      }

      final event = jsonDecode(responseBody) as Map<String, dynamic>;

      logger.debugLog('Event sent successfully: $event');
      return event;
    } catch (e) {
      logger.debugLog('Exception sending event: $e', error: e);
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Reads the response body as a string.
  ///
  /// This is a helper method that makes it easier to test the service.
  Future<String> _readResponseAsString(HttpClientResponse response) async {
    final completer = Completer<String>();
    final contents = StringBuffer();

    response.listen(
      (data) {
        contents.write(utf8.decode(data));
      },
      onDone: () {
        completer.complete(contents.toString());
      },
      onError: completer.completeError,
      cancelOnError: true,
    );

    return completer.future;
  }
}
