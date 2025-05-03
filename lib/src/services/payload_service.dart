import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:marktag/src/models/marktag_event.dart';
import 'package:marktag/src/services/ip_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/user_service.dart';

/// A service responsible for creating payloads for MarkTag events.
class PayloadService {
  /// Creates an instance of [PayloadService].
  ///
  /// Requires a [UserService] to fetch user data, an [IPService] to fetch IP
  /// information, and an optional [LoggerService] for logging purposes.
  PayloadService({
    required this.userService,
    required this.ipService,
    LoggerService? logger,
  }) : logger = logger ??  LoggerService(name: 'PayloadService');

  /// The service used to fetch user information.
  final UserService userService;

  /// The service used to fetch IP information.
  final IPService ipService;

  /// The logger used for logging messages.
  final LoggerService logger;

  /// Creates a payload for a given [MarkTagEvent].
  ///
  /// The payload includes user information, IP information, and event details.
  /// Returns a [Future] that completes with the payload as a [Map].
  Future<Map<String, dynamic>> createPayload(MarkTagEvent event) async {
    if (event.email != null || event.phone != null) {
      await userService.setUser(
        email: event.email,
        phone: event.phone,
      );
    }
    final user = await userService.getUser();
    final ipInfo = await ipService.getIpInfo();
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final serial = androidInfo.serialNumber;
      if (serial == 'unknown') {
        deviceId = androidInfo.id;
      } else {
        deviceId = serial;
      }
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
    final payload = {
      'x-cf-ip': ipInfo.ip,
      'x-cf-loc': ipInfo.loc,
      'event_source': 'mobile',
      ...user.toJson(),
      'event': event.event,
      'pageUrl': event.pageUrl,
      'deviceId': deviceId,
      'products': event.items?.map((e) => e.toJson()).toList(),
      ...?event.metadata,
    };
    logger.debugLog('Payload: $payload');
    return payload;
  }
}
