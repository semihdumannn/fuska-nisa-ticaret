import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_campaign_model.dart';
import '../../data/providers/campaign_data_providers.dart';

/// Aktif kampanya listesi (6 saat cache)
final campaignsProvider =
    FutureProvider<List<ApiCampaignModel>>((ref) async {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.getCampaigns();
});

/// Sadece şu an aktif olan kampanyalar
final activeCampaignsProvider =
    FutureProvider<List<ApiCampaignModel>>((ref) async {
  final campaigns = await ref.watch(campaignsProvider.future);
  return campaigns.where((c) => c.isCurrentlyActive).toList();
});
