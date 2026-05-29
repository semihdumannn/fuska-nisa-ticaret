import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../datasources/campaign_remote_datasource.dart';
import '../models/api_campaign_model.dart';

class CampaignRepositoryImpl {
  final ICampaignRemoteDatasource _remoteDatasource;
  final CacheManager _cacheManager;

  CampaignRepositoryImpl({
    required ICampaignRemoteDatasource remoteDatasource,
    required CacheManager cacheManager,
  })  : _remoteDatasource = remoteDatasource,
        _cacheManager = cacheManager;

  Future<List<ApiCampaignModel>> getCampaigns({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached =
          _cacheManager.getCachedData<List<dynamic>>(CacheKeys.campaigns);
      if (cached != null) {
        try {
          return cached
              .map((item) =>
                  ApiCampaignModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {
          await _cacheManager.invalidate(CacheKeys.campaigns);
        }
      }
    }

    final models = await _remoteDatasource.getCampaigns();

    await _cacheManager.cacheData(
      CacheKeys.campaigns,
      models.map((m) => m.toMap()).toList(),
      ttl: CacheKeys.campaignsTtl,
    );

    return models;
  }

  Future<void> invalidateCache() => _cacheManager.invalidate(CacheKeys.campaigns);
}
