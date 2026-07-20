import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/booking_model.dart';

class BookingService {
  final ApiClient _apiClient = ApiClient();

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    
    final parsed = DateTime.tryParse(dateString);
    if (parsed != null) return parsed;

    // Try parsing "17 April 2024" or "17 April, 2024"
    final regex = RegExp(r'(\d{1,2})\s+([a-zA-Z]+)[,\s]+(\d{4})');
    final match = regex.firstMatch(dateString);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final year = int.parse(match.group(3)!);
      
      int month = 1;
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      for (int i = 0; i < months.length; i++) {
        if (monthStr.startsWith(months[i])) {
          month = i + 1;
          break;
        }
      }
      return DateTime(year, month, day);
    }

    // Try parsing "DD/MM/YYYY" or "DD-MM-YYYY"
    final regex2 = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
    final match2 = regex2.firstMatch(dateString);
    if (match2 != null) {
      final day = int.parse(match2.group(1)!);
      final month = int.parse(match2.group(2)!);
      final year = int.parse(match2.group(3)!);
      return DateTime(year, month, day);
    }
    
    return null;
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
