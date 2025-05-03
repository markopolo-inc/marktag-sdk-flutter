import 'dart:developer';

import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/services/event_service.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/payload_service.dart';
import 'package:marktag/src/services/user_service.dart';

/// Flutter SDK for Marktag.
class Marktag {
  Marktag._();

  /// The singleton instance of the [Marktag] class.
  static final Marktag instance = Marktag._();

  /// Initializes the [Marktag] instance with the given [tag].
  void init({
    required String tag,
    bool? enableLogging,
  }) {
    _tag = tag;
    _userService = UserService();
    _eventService = EventService(tag: tag);
    _payloadService = PayloadService(
      userService: _userService,
      ipService: IPService(),
    );
  }

  String? _tag;

  /// The [EventService] instance.
  EventService? _eventService;

  /// The [PayloadService] instance.
  PayloadService? _payloadService;

  /// The [UserService] instance.
  late UserService _userService;

  /// Logs an event to the Marktag server.
  Future<void> logEvent(MarkTagEvent event) async {
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Identifies a user with the given [email], [name], and [phone].
  Future<void> identifyUser({
    String? email,
    String? name,
    String? phone,
  }) async {
    await _userService.setUser(email: email, name: name, phone: phone);
  }

  /// Logs a login event.
  Future<void> logLogin({
    String? email,
    String? name,
    String? phone,
  }) async {
    await _userService.setUser(email: email, name: name, phone: phone);
    final event = MarkTagEvent(
      event: 'Login',
      metadata: {
        'email': email,
        'name': name,
        'phone': phone,
      },
    );
    final payload = await _payloadService?.createPayload(event);
    await _sendEvent(payload);
  }

  /// Sends an event to the Marktag server.
  Future<void> _sendEvent(Map<String, dynamic>? payload) async {
    if (_tag == null) {
      log(
        'Marktag must be initialized with init() before calling any methods',
      );
      return;
    }

    if (payload == null) {
      return;
    }
    await _eventService?.markEvent(payload);
  }
}
