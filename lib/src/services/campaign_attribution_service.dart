import 'dart:convert';
import 'package:marktag/src/models/campaign_context.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:meta/meta.dart';

/// A service for persisting and reading back push-notification campaign
/// click attribution, backed by [StorageService].
///
/// Last-click-wins: [recordClick] always overwrites any existing context.
/// [getActiveContext] lazily expires and purges the stored context once it
/// is older than [_ttl].
class CampaignAttributionService {
  /// Creates a [CampaignAttributionService] instance.
  ///
  /// [storageService], [logger], [now], and [ttl] can be injected for
  /// testability.
  CampaignAttributionService({
    StorageService? storageService,
    LoggerService? logger,
    @visibleForTesting DateTime Function()? now,
    @visibleForTesting Duration? ttl,
  }) : _storageService = storageService ?? StorageService(),
       _logger = logger ?? LoggerService(name: 'CampaignAttributionService'),
       _now = now ?? DateTime.now,
       _ttl = ttl ?? const Duration(days: 30);

  static const String _campaignKey = 'mt_campaign_context';

  final StorageService _storageService;
  final LoggerService _logger;
  final DateTime Function() _now;
  final Duration _ttl;

  /// Persists the tapped campaign as the current attribution context.
  ///
  /// Always overwrites any previously stored context (last-click-wins).
  Future<void> recordClick({
    required String campaignId,
    required String msid,
    required String contentId,
    required String nodeId,
  }) async {
    final context = CampaignContext(
      campaignId: campaignId,
      contentId: contentId,
      nodeId: nodeId,
      capturedAtMs: _now().millisecondsSinceEpoch,
      msid: msid,
    );
    try {
      await _storageService.setString(
        _campaignKey,
        _encodeJson(context.toJson()),
      );
      _logger.debugLog('Campaign context recorded: $context');
    } catch (error, stack) {
      _logger.debugLog(
        'Error in recordClick: $error',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Returns the active campaign context, or `null` if none exists or it
  /// has expired (in which case it is purged from storage on this read).
  ///
  /// A malformed stored value is treated as "no context" rather than
  /// thrown, since a corrupted attribution blob should never block normal
  /// event tracking.
  Future<CampaignContext?> getActiveContext() async {
    try {
      final raw = await _storageService.getString(_campaignKey);
      if (raw == null) return null;

      final context = CampaignContext.fromJson(_decodeJson(raw));
      final ageMs = _now().millisecondsSinceEpoch - context.capturedAtMs;
      if (ageMs > _ttl.inMilliseconds) {
        await _storageService.remove(_campaignKey);
        _logger.debugLog(
          'Campaign context expired, purged: ${context.campaignId}',
        );
        return null;
      }
      return context;
    } on Object catch (error, stack) {
      _logger.debugLog(
        'Error in getActiveContext: $error',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Decodes a JSON string to a Map.
  Map<String, dynamic> _decodeJson(String jsonStr) {
    final dynamic decoded = json.decode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    } else {
      throw const FormatException('Decoded JSON is not a Map');
    }
  }

  /// Encodes a Map to a JSON string.
  String _encodeJson(Map<String, dynamic> map) => json.encode(map);
}
