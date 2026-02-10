import 'api_service.dart';

class OrdersApiService {
  final ApiService _apiService;

  OrdersApiService(this._apiService);

  /// Create a new sales order
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    final response = await _apiService.post(
      ApiConfig.orders,
      body: orderData,
    );
    return response as Map<String, dynamic>;
  }

  /// Get order by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _apiService.get('${ApiConfig.orders}/$orderId');
    return response as Map<String, dynamic>;
  }

  /// Get orders for a customer
  Future<List<dynamic>> getCustomerOrders({
    required String customerId,
    String? status,
  }) async {
    final queryParams = {'customerId': customerId};
    if (status != null) {
      queryParams['status'] = status;
    }
    final response = await _apiService.get(
      ApiConfig.orders,
      queryParams: queryParams,
    );
    return response as List<dynamic>;
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    final response = await _apiService.put(
      '${ApiConfig.orders}/$orderId/status',
      body: {
        'status': status,
        'notes': notes,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Cancel order
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.orders}/$orderId/cancel',
      body: {'reason': reason},
    );
    return response as Map<String, dynamic>;
  }
}
