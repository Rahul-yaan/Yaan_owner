import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/hotel_model.dart';

class HotelService {
  final ApiClient _apiClient = ApiClient();

  Future<List<HotelModel>> getHotels() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.hotels);
      if (response.statusCode == 200) {
        // Handle Laravel responses which often wrap data in a 'data' key
        List data = [];
        if (response.data is Map) {
          if (response.data.containsKey('data')) data = response.data['data'];
          else if (response.data.containsKey('hotels')) data = response.data['hotels'];
        } else if (response.data is List) {
          data = response.data;
        }
        return data.map((json) => HotelModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<HotelModel> addHotel(HotelModel hotel) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.hotels,
        data: hotel.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        var data = response.data;
        if (data is Map) {
          if (data.containsKey('hotel')) {
              data = data['hotel'];
          } else if (data.containsKey('data')) {
              data = data['data'];
          }
        }
            
        if (data is Map<String, dynamic>) {
            return HotelModel.fromJson(data);
        }
        
        throw Exception('Invalid response format when adding hotel');
      }
      throw Exception('Failed to add hotel');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<HotelModel> updateHotel(int hotelId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.hotels}/$hotelId',
        data: data,
      );
      if (response.statusCode == 200) {
        var responseData = response.data;
        if (responseData is Map) {
          if (responseData.containsKey('hotel')) {
              responseData = responseData['hotel'];
          } else if (responseData.containsKey('data')) {
              responseData = responseData['data'];
          }
        }
        
        if (responseData is Map<String, dynamic>) {
            return HotelModel.fromJson(responseData);
        }
        
        throw Exception('Invalid response format when updating hotel');
      }
      throw Exception('Failed to update hotel');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> uploadHotelImages(int hotelId, Map<String, String> uploadedImages) async {
    if (uploadedImages.isEmpty) return;
    try {
      FormData formData = FormData();
      for (var entry in uploadedImages.entries) {
        String label = entry.key;
        String path = entry.value;
        String fieldName = 'images[]';
        
        if (label.toLowerCase().contains('pan')) fieldName = 'pan_card';
        else if (label.toLowerCase().contains('gst')) fieldName = 'gst_image';
        else if (label.toLowerCase().contains('fssai')) fieldName = 'fssai_license';
        else if (label.toLowerCase().contains('business')) fieldName = 'business_proof';
        else if (label.toLowerCase().contains('front')) fieldName = 'aadhar_front';
        else if (label.toLowerCase().contains('back')) fieldName = 'aadhar_back';
        
        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(path),
          ),
        );
      }
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.hotels}/$hotelId/images',
        data: formData,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload images');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
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
