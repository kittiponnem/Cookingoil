import 'api_service.dart';

class PickupApiService {
  final ApiService _apiService;

  PickupApiService(this._apiService);

  /// Create a new UCO pickup request
  Future<Map<String, dynamic>> createPickup({
    required Map<String, dynamic> pickupData,
  }) async {
    final response = await _apiService.post(
      ApiConfig.pickups,
      body: pickupData,
    );
    return response as Map<String, dynamic>;
  }

  /// Get pickup by ID
  Future<Map<String, dynamic>> getPickupById(String pickupId) async {
    final response = await _apiService.get('${ApiConfig.pickups}/$pickupId');
    return response as Map<String, dynamic>;
  }

  /// Get pickups for a customer
  Future<List<dynamic>> getCustomerPickups({
    required String customerId,
    String? status,
  }) async {
    final queryParams = {'customerId': customerId};
    if (status != null) {
      queryParams['status'] = status;
    }
    final response = await _apiService.get(
      ApiConfig.pickups,
      queryParams: queryParams,
    );
    return response as List<dynamic>;
  }

  /// Update pickup status
  Future<Map<String, dynamic>> updatePickupStatus({
    required String pickupId,
    required String status,
    String? notes,
  }) async {
    final response = await _apiService.put(
      '${ApiConfig.pickups}/$pickupId/status',
      body: {
        'status': status,
        'notes': notes,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Submit quality assessment
  Future<Map<String, dynamic>> submitQualityAssessment({
    required String pickupId,
    required Map<String, dynamic> qualityData,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.pickups}/$pickupId/quality',
      body: qualityData,
    );
    return response as Map<String, dynamic>;
  }
}
