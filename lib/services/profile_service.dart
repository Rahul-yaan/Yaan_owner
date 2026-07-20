import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/owner_profile_model.dart';
import '../core/models/user_model.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get('${ApiEndpoints.baseUrl}/owner/profile');
      
      final profileJson = response.data['profile'];
      final userJson = response.data['user'];
      
      OwnerProfileModel? profile;
      if (profileJson != null) {
        profile = OwnerProfileModel.fromJson(profileJson);
      }
      
      UserModel? user;
      if (userJson != null) {
        user = UserModel.fromJson(userJson);
      }
      
      return {
        'profile': profile,
        'user': user,
      };
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<OwnerProfileModel> updateProfile({
    required Map<String, String> data,
    Map<String, File>? files,
  }) async {
    try {
      FormData formData = FormData.fromMap(data);

      if (files != null) {
        for (var entry in files.entries) {
          formData.files.add(
            MapEntry(
              entry.key,
              await MultipartFile.fromFile(entry.value.path, filename: entry.value.path.split('/').last),
            ),
          );
        }
      }

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.baseUrl}/owner/profile',
        data: formData,
      );

      var responseData = response.data;
      if (responseData is Map) {
        var profileJson = responseData['profile'] ?? responseData['data'];
        if (profileJson is Map<String, dynamic>) {
          return OwnerProfileModel.fromJson(profileJson);
        }
      }
      return OwnerProfileModel(id: 0, userId: 0); // fallback
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      if (e.response?.data is Map) {
        var data = e.response?.data as Map;
        if (data.containsKey('errors')) {
          var errors = data['errors'];
          if (errors is Map) {
             return errors.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
          }
        }
        return data['message'] ?? e.response?.statusMessage ?? 'An error occurred';
      }
      return e.response?.statusMessage ?? 'An error occurred';
    }
    return e.message ?? 'Unknown error';
  }
}
