import 'package:meta/meta.dart';

/// Represents the attribution context captured when a user taps a campaign
/// push notification.
///
/// [campaignId], [contentId], and [nodeId] mirror the FCM data payload
/// fields of the same name (defaulting to an empty string when absent, same
/// convention used for the push-tracking event metadata).
/// [msid] is the live session id at the moment of capture, used later to
/// compute `is_same_session`.
@immutable
class CampaignContext {
  /// Creates a [CampaignContext] instance.
  const CampaignContext({
    required this.campaignId,
    required this.contentId,
    required this.nodeId,
    required this.capturedAtMs,
    required this.msid,
  });

  /// Creates a [CampaignContext] from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory CampaignContext.fromJson(Map<String, dynamic> json) {
    if (json['campaignId'] == null || json['campaignId'] is! String) {
      throw const FormatException('Missing or invalid campaignId');
    }
    if (json['capturedAtMs'] == null || json['capturedAtMs'] is! int) {
      throw const FormatException('Missing or invalid capturedAtMs');
    }
    if (json['msid'] == null || json['msid'] is! String) {
      throw const FormatException('Missing or invalid msid');
    }
    return CampaignContext(
      campaignId: json['campaignId'] as String,
      contentId: json['contentId'] as String? ?? '',
      nodeId: json['nodeId'] as String? ?? '',
      capturedAtMs: json['capturedAtMs'] as int,
      msid: json['msid'] as String,
    );
  }

  /// The campaign identifier (required).
  final String campaignId;

  /// The content identifier, empty string if not present in the tap.
  final String contentId;

  /// The node identifier, empty string if not present in the tap.
  final String nodeId;

  /// The epoch-millisecond timestamp this context was captured at.
  final int capturedAtMs;

  /// The live session id (msid) at capture time.
  final String msid;

  /// Converts this [CampaignContext] instance to a JSON map.
  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'contentId': contentId,
    'nodeId': nodeId,
    'capturedAtMs': capturedAtMs,
    'msid': msid,
  };

  @override
  bool operator ==(Object other) {
    if (other is! CampaignContext) return false;
    return campaignId == other.campaignId &&
        contentId == other.contentId &&
        nodeId == other.nodeId &&
        capturedAtMs == other.capturedAtMs &&
        msid == other.msid;
  }

  @override
  int get hashCode =>
      Object.hash(campaignId, contentId, nodeId, capturedAtMs, msid);

  @override
  String toString() =>
      'CampaignContext(campaignId: $campaignId, contentId: $contentId, '
      'nodeId: $nodeId, capturedAtMs: $capturedAtMs, msid: $msid)';
}
