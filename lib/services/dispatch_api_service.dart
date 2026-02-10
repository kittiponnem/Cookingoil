import 'api_service.dart';

class DispatchApiService {
  final ApiService _apiService;

  DispatchApiService(this._apiService);

  /// Create and assign a new job
  Future<Map<String, dynamic>> createJob({
    required Map<String, dynamic> jobData,
  }) async {
    final response = await _apiService.post(
      ApiConfig.dispatchJobs,
      body: jobData,
    );
    return response as Map<String, dynamic>;
  }

  /// Assign job to driver
  Future<Map<String, dynamic>> assignJobToDriver({
    required String jobId,
    required String driverUid,
    required String vehicleId,
    required DateTime scheduledDate,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.dispatchJobs}/$jobId/assign',
      body: {
        'driverUid': driverUid,
        'vehicleId': vehicleId,
        'scheduledDate': scheduledDate.toIso8601String(),
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Update job status
  Future<Map<String, dynamic>> updateJobStatus({
    required String jobId,
    required String status,
    double? lat,
    double? lng,
    String? notes,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.dispatchJobs}/$jobId/status',
      body: {
        'status': status,
        'lat': lat,
        'lng': lng,
        'notes': notes,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Complete job with proof
  Future<Map<String, dynamic>> completeJob({
    required String jobId,
    required List<String> photoUrls,
    required String signatureUrl,
    double? actualQty,
    String? actualUom,
    Map<String, dynamic>? qualityFlags,
    String? notes,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.dispatchJobs}/$jobId/complete',
      body: {
        'photoUrls': photoUrls,
        'signatureUrl': signatureUrl,
        'actualQty': actualQty,
        'actualUom': actualUom,
        'qualityFlags': qualityFlags,
        'notes': notes,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Get jobs for a driver
  Future<List<dynamic>> getDriverJobs({
    required String driverUid,
    String? status,
    DateTime? date,
  }) async {
    final queryParams = {'driverUid': driverUid};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date.toIso8601String();

    final response = await _apiService.get(
      ApiConfig.dispatchJobs,
      queryParams: queryParams,
    );
    return response as List<dynamic>;
  }

  /// Get all jobs for dispatch board
  Future<List<dynamic>> getAllJobs({
    String? status,
    DateTime? date,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date.toIso8601String();

    final response = await _apiService.get(
      ApiConfig.dispatchJobs,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    return response as List<dynamic>;
  }
}
