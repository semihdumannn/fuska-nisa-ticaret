import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_campaign_model.dart';

abstract class ICampaignRemoteDatasource {
  Future<List<ApiCampaignModel>> getCampaigns();
}

class CampaignRemoteDatasource implements ICampaignRemoteDatasource {
  final Dio _dio;

  CampaignRemoteDatasource(this._dio);

  @override
  Future<List<ApiCampaignModel>> getCampaigns() async {
    try {
      final response = await _dio.get(ApiEndpoints.campaigns);
      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiCampaignModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
