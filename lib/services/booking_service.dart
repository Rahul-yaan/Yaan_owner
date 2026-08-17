import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/booking_model.dart';
import '../core/utils/date_formatter.dart';

class BookingService {
  final ApiClient _apiClient = ApiClient();

  DateTime? _parseDate(String dateString) {
    return DateFormatter.parseDate(dateString);
  }

  Future<List<BookingModel>> getBookings({String filter = 'all'}) async {
    try {
      // Always fetch all bookings from the backend to do proper date filtering locally
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/owner/bookings',
        queryParameters: {'filter': 'all'},
      );
      
      final List<dynamic> data = response.data['bookings'] ?? [];
      List<BookingModel> allBookings = data.map((json) => BookingModel.fromJson(json)).toList();

      if (filter == 'all') return allBookings;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return allBookings.where((booking) {
        DateTime? bookingDate;
        
        // Prioritize bookingDate date for filtering (this is where the backend stores the actual booking date)
        if (booking.bookingDate.isNotEmpty) {
          bookingDate = _parseDate(booking.bookingDate);
        }
        
        // Fallback to checkIn date
        if (bookingDate == null && booking.checkIn.isNotEmpty) {
          bookingDate = _parseDate(booking.checkIn);
        }
        
        // If checkIn is empty or unparseable, try falling back to slot
        if (bookingDate == null && booking.slot.isNotEmpty) {
          bookingDate = _parseDate(booking.slot);
        }
        
        // Fallback to createdAt if nothing else works
        if (bookingDate == null && booking.createdAt.isNotEmpty) {
          bookingDate = _parseDate(booking.createdAt);
        }

        // If still no date, put it in older as a fallback
        if (bookingDate == null) return filter == 'older';

        final dateOnly = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

        if (filter == 'today') {
          return dateOnly.isAtSameMomentAs(today);
        } else if (filter == 'upcoming') {
          return dateOnly.isAfter(today);
        } else if (filter == 'older') {
          return dateOnly.isBefore(today);
        }

        return false;
      }).toList();
      
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  Future<BookingModel> getBookingDetails(int id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/owner/bookings/$id',
      );
      return BookingModel.fromJson(response.data['booking']);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to get booking details: $e');
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['message'] ?? e.response?.statusMessage ?? 'An error occurred';
    }
    return e.message ?? 'Unknown error';
  }
}
