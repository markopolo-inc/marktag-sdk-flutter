import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/campaign_context.dart';

void main() {
  group('CampaignContext', () {
    const context = CampaignContext(
      campaignId: 'camp_789',
      contentId: 'content_abc',
      nodeId: 'node_1',
      capturedAtMs: 1700000000000,
      msid: 'msid-1',
    );

    test('can be constructed with all fields', () {
      expect(context.campaignId, 'camp_789');
      expect(context.contentId, 'content_abc');
      expect(context.nodeId, 'node_1');
      expect(context.capturedAtMs, 1700000000000);
      expect(context.msid, 'msid-1');
    });

    test('supports value equality', () {
      const other = CampaignContext(
        campaignId: 'camp_789',
        contentId: 'content_abc',
        nodeId: 'node_1',
        capturedAtMs: 1700000000000,
        msid: 'msid-1',
      );
      const different = CampaignContext(
        campaignId: 'camp_other',
        contentId: 'content_abc',
        nodeId: 'node_1',
        capturedAtMs: 1700000000000,
        msid: 'msid-1',
      );
      expect(context, other);
      expect(context == different, isFalse);
    });

    test('hashCode returns consistent values for equal objects', () {
      const other = CampaignContext(
        campaignId: 'camp_789',
        contentId: 'content_abc',
        nodeId: 'node_1',
        capturedAtMs: 1700000000000,
        msid: 'msid-1',
      );
      expect(context.hashCode, other.hashCode);
    });

    test('toJson includes all fields', () {
      expect(context.toJson(), {
        'campaignId': 'camp_789',
        'contentId': 'content_abc',
        'nodeId': 'node_1',
        'capturedAtMs': 1700000000000,
        'msid': 'msid-1',
      });
    });

    test('fromJson creates CampaignContext from valid JSON', () {
      final json = {
        'campaignId': 'camp_789',
        'contentId': 'content_abc',
        'nodeId': 'node_1',
        'capturedAtMs': 1700000000000,
        'msid': 'msid-1',
      };
      expect(CampaignContext.fromJson(json), context);
    });

    test('fromJson defaults contentId/nodeId to empty string if absent', () {
      final json = {
        'campaignId': 'camp_789',
        'capturedAtMs': 1700000000000,
        'msid': 'msid-1',
      };
      final result = CampaignContext.fromJson(json);
      expect(result.contentId, '');
      expect(result.nodeId, '');
    });

    test('fromJson throws if campaignId is missing', () {
      final json = {'capturedAtMs': 1700000000000, 'msid': 'msid-1'};
      expect(() => CampaignContext.fromJson(json), throwsFormatException);
    });

    test('fromJson throws if capturedAtMs is missing', () {
      final json = {'campaignId': 'camp_789', 'msid': 'msid-1'};
      expect(() => CampaignContext.fromJson(json), throwsFormatException);
    });

    test('fromJson throws if msid is missing', () {
      final json = {'campaignId': 'camp_789', 'capturedAtMs': 1700000000000};
      expect(() => CampaignContext.fromJson(json), throwsFormatException);
    });

    test('fromJson and toJson round-trip', () {
      final json = context.toJson();
      expect(CampaignContext.fromJson(json), context);
    });

    test('toString returns expected format', () {
      expect(
        context.toString(),
        'CampaignContext(campaignId: camp_789, contentId: content_abc, '
        'nodeId: node_1, capturedAtMs: 1700000000000, msid: msid-1)',
      );
    });
  });
}
