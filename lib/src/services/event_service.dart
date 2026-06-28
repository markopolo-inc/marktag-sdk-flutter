import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marktag/src/services/logger_service.dart';

/// A service responsible for sending events to the MarkTag server.
class EventService {
  /// Creates an instance of [EventService].
  ///
  /// Requires a [tag] parameter that specifies the MarkTag server endpoint.
  /// Optionally accepts a [LoggerService] for logging and an [http.Client]
  /// for HTTP requests (useful for tests or custom networking).
  EventService({
    required this.tag,
    this.tagId,
    LoggerService? logger,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       logger = logger ?? LoggerService(name: 'EventService');

  /// The MarkTag server tag/domain.
  final String tag;

  /// The tenant identifier sent as the `tagId` query param. Optional —
  /// omitted on server-side (mobile) where the host itself identifies the
  /// tenant.
  final String? tagId;

  /// The logger used for logging messages.
  final LoggerService logger;

  final http.Client _httpClient;

  /// Sends an event payload to the MarkTag server.
  ///
  /// Takes a [payload] containing the event data and sends it to the server.
  /// Returns a [Future] that completes with the server response as a [Map].
  ///
  /// Throws [Exception] if the request fails.
  Future<Map<String, dynamic>> markEvent(Map<String, dynamic> payload) async {
    logger.debugLog('Sending event to $tag with payload: $payload');

    final url = (tagId == null || tagId!.isEmpty)
        ? Uri.parse('https://$tag/mark')
        : Uri.parse('https://$tag/mark?tagId=$tagId');

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseBody = response.body;

      if (response.statusCode != 201) {
        logger.debugLog('Error sending event: $responseBody');
        throw Exception(
          'Failed to send event. Status code: ${response.statusCode}',
        );
      }

      final event = jsonDecode(responseBody) as Map<String, dynamic>;

      logger.debugLog('Event sent successfully: $event');
      return event;
    } catch (e) {
      logger.debugLog('Exception sending event: $e', error: e);
      rethrow;
    }
  }
}
