import 'api_service.dart';

class AuthApiService {
  final ApiService _apiService;

  AuthApiService(this._apiService);

  /// Login with email/password for internal users
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.authLogin,
      body: {
        'email': email,
        'password': password,
        'loginType': 'email',
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Login with phone OTP for customers
  Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    final response = await _apiService.post(
      '${ApiConfig.authLogin}/send-otp',
      body: {'phone': phone},
    );
    return response as Map<String, dynamic>;
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiService.post(
      '${ApiConfig.authLogin}/verify-otp',
      body: {
        'phone': phone,
        'otp': otp,
      },
    );
    return response as Map<String, dynamic>;
  }
}
