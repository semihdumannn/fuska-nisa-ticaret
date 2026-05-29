import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/campaign_remote_datasource.dart';
import '../repositories/campaign_repository_impl.dart';

final campaignRemoteDatasourceProvider =
    Provider<ICampaignRemoteDatasource>((ref) {
  return CampaignRemoteDatasource(ref.watch(apiClientProvider).dio);
});

final campaignRepositoryProvider = Provider<CampaignRepositoryImpl>((ref) {
  return CampaignRepositoryImpl(
    remoteDatasource: ref.watch(campaignRemoteDatasourceProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});
