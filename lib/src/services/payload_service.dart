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
    this.logger = const LoggerService(name: 'PayloadService'),
  });

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
    final payload = {
      'x-cf-ip': ipInfo.ip,
      'x-cf-loc': ipInfo.loc,
      'event_source': 'mobile',
      ...user.toJson(),
      'event': event.event,
      'pageUrl': event.pageUrl,
      'products': event.items?.map((e) => e.toJson()).toList(),
      ...?event.metadata,
    };
    logger.debugLog('Payload: $payload');
    return payload;
  }
}
