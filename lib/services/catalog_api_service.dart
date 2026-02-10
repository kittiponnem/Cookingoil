import 'api_service.dart';

class CatalogApiService {
  final ApiService _apiService;

  CatalogApiService(this._apiService);

  /// Get products catalog (optionally filtered by customer)
  Future<List<dynamic>> getProducts({String? customerId}) async {
    final queryParams = customerId != null ? {'customerId': customerId} : null;
    final response = await _apiService.get(
      ApiConfig.catalogProducts,
      queryParams: queryParams,
    );
    return response as List<dynamic>;
  }

  /// Get product by SKU
  Future<Map<String, dynamic>> getProductBySku(String sku) async {
    final response = await _apiService.get('${ApiConfig.catalogProducts}/$sku');
    return response as Map<String, dynamic>;
  }

  /// Get product pricing
  Future<Map<String, dynamic>> getProductPricing({
    required String sku,
    required String customerId,
    required int quantity,
  }) async {
    final response = await _apiService.get(
      '${ApiConfig.catalogProducts}/$sku/pricing',
      queryParams: {
        'customerId': customerId,
        'quantity': quantity.toString(),
      },
    );
    return response as Map<String, dynamic>;
  }
}
