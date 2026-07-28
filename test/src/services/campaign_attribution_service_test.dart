import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/services/campaign_attribution_service.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late MockStorageService storage;
  late MockLoggerService logger;
  late DateTime now;
  late CampaignAttributionService service;

  const campaignKey = 'mt_campaign_context';

  setUp(() {
    storage = MockStorageService();
    logger = MockLoggerService();
    now = DateTime(2026, 1, 10, 12);
    when(() => logger.debugLog(any())).thenReturn(null);
    service = CampaignAttributionService(
      storageService: storage,
      logger: logger,
      now: () => now,
    );
  });

  group('CampaignAttributionService', () {
    group('recordClick', () {
      test(
        'writes the context as JSON, keyed by mt_campaign_context',
        () async {
          when(
            () => storage.setString(campaignKey, any()),
          ).thenAnswer((_) async => true);

          await service.recordClick(
            campaignId: 'camp_789',
            msid: 'msid-1',
            contentId: 'content_abc',
            nodeId: 'node_1',
          );

          final captured = verify(
            () => storage.setString(campaignKey, captureAny()),
          ).captured;
          expect(captured.single, contains('"campaignId":"camp_789"'));
          expect(captured.single, contains('"msid":"msid-1"'));
          expect(
            captured.single,
            contains('"capturedAtMs":${now.millisecondsSinceEpoch}'),
          );
        },
      );

      test('always overwrites — last click wins, no merge', () async {
        when(
          () => storage.setString(campaignKey, any()),
        ).thenAnswer((_) async => true);

        await service.recordClick(
          campaignId: 'camp_1',
          msid: 'msid-1',
          contentId: '',
          nodeId: '',
        );
        await service.recordClick(
          campaignId: 'camp_2',
          msid: 'msid-2',
          contentId: '',
          nodeId: '',
        );

        final captured = verify(
          () => storage.setString(campaignKey, captureAny()),
        ).captured;
        expect(captured, hasLength(2));
        expect(captured[0], isNot(equals(captured[1])));
        expect(captured[1], contains('"campaignId":"camp_2"'));
      });

      test('logs and rethrows on storage failure', () async {
        when(
          () => storage.setString(campaignKey, any()),
        ).thenThrow(Exception('write failed'));

        expect(
          () => service.recordClick(
            campaignId: 'camp_789',
            msid: 'msid-1',
            contentId: '',
            nodeId: '',
          ),
          throwsException,
        );
      });
    });

    group('getActiveContext', () {
      test('returns null when nothing is stored', () async {
        when(
          () => storage.getString(campaignKey),
        ).thenAnswer((_) async => null);
        expect(await service.getActiveContext(), isNull);
      });

      test('returns the context when within the 30-day TTL', () async {
        final capturedAt = now.subtract(const Duration(days: 29));
        when(() => storage.getString(campaignKey)).thenAnswer(
          (_) async =>
              '{"campaignId":"camp_789","contentId":"content_abc",'
              '"nodeId":"node_1","capturedAtMs":'
              '${capturedAt.millisecondsSinceEpoch},"msid":"msid-1"}',
        );

        final result = await service.getActiveContext();

        expect(result, isNotNull);
        expect(result!.campaignId, 'camp_789');
        verifyNever(() => storage.remove(any()));
      });

      test('purges and returns null once past the 30-day TTL', () async {
        final capturedAt = now.subtract(const Duration(days: 31));
        when(() => storage.getString(campaignKey)).thenAnswer(
          (_) async =>
              '{"campaignId":"camp_789","contentId":"","nodeId":"",'
              '"capturedAtMs":${capturedAt.millisecondsSinceEpoch},'
              '"msid":"msid-1"}',
        );
        when(
          () => storage.remove(campaignKey),
        ).thenAnswer((_) async => true);

        final result = await service.getActiveContext();

        expect(result, isNull);
        verify(() => storage.remove(campaignKey)).called(1);
      });

      test('respects a custom TTL override', () async {
        final shortTtlService = CampaignAttributionService(
          storageService: storage,
          logger: logger,
          now: () => now,
          ttl: const Duration(hours: 1),
        );
        final capturedAt = now.subtract(const Duration(hours: 2));
        when(() => storage.getString(campaignKey)).thenAnswer(
          (_) async =>
              '{"campaignId":"camp_789","contentId":"","nodeId":"",'
              '"capturedAtMs":${capturedAt.millisecondsSinceEpoch},'
              '"msid":"msid-1"}',
        );
        when(
          () => storage.remove(campaignKey),
        ).thenAnswer((_) async => true);

        expect(await shortTtlService.getActiveContext(), isNull);
      });

      test('treats malformed JSON as no context, not a thrown error', () async {
        when(
          () => storage.getString(campaignKey),
        ).thenAnswer((_) async => 'not valid json');

        expect(await service.getActiveContext(), isNull);
      });

      test('treats a decode failure as no context', () async {
        when(
          () => storage.getString(campaignKey),
        ).thenAnswer((_) async => '"just a string"');

        expect(await service.getActiveContext(), isNull);
      });
    });
  });
}
