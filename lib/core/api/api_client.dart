import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors for authentication and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Retrieve the stored token from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        
        // If the token exists, add it to the request header
        if (token != null) {
          print("API_CLIENT: Attaching Token to Request");
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          print("API_CLIENT: NO TOKEN FOUND IN SharedPreferences (api_token)");
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // You can handle global response parsing here if needed
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Handle global errors here
        if (e.response?.statusCode == 401) {
          // Token is invalid or expired. You can trigger a global logout event here.
          // e.g., clear SharedPreferences and navigate to Login Screen
        }
        return handler.next(e);
      },
    ));
  }

  // Expose the configured Dio instance
  Dio get dio => _dio;
}
