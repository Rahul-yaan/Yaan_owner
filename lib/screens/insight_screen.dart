import 'package:flutter/material.dart';
import '../core/models/booking_model.dart';
import '../services/booking_service.dart';
import '../core/utils/date_formatter.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final BookingService _bookingService = BookingService();
  String _selectedFilter = 'Today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<BookingModel> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final bookings = await _bookingService.getBookings(filter: 'all');
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  DateTime? _parseDate(String dateString) {
    return DateFormatter.parseDate(dateString);
  }

  List<BookingModel> get _filteredBookings {
    if (_allBookings.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allBookings.where((booking) {
      DateTime? bookingDate;
      
      // Use the scheduled booking date as the primary date for Insights
      if (booking.bookingDate.isNotEmpty) {
        bookingDate = _parseDate(booking.bookingDate);
      }
      if (bookingDate == null && booking.checkIn.isNotEmpty) {
        bookingDate = _parseDate(booking.checkIn);
      }
      if (bookingDate == null && booking.createdAt.isNotEmpty) {
        bookingDate = _parseDate(booking.createdAt);
      }

      if (bookingDate == null) return true; // Include if no date
      
      final dateOnly = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

      if (_selectedFilter == 'Today') {
        return dateOnly.isAtSameMomentAs(today);
      } else if (_selectedFilter == 'Last 7 Days') {
        final last7Days = today.subtract(const Duration(days: 7));
        return (dateOnly.isAfter(last7Days) || dateOnly.isAtSameMomentAs(last7Days)) && 
               (dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today));
      } else if (_selectedFilter == 'Last 15 Days') {
        final last15Days = today.subtract(const Duration(days: 15));
        return (dateOnly.isAfter(last15Days) || dateOnly.isAtSameMomentAs(last15Days)) && 
               (dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today));
      } else if (_selectedFilter == 'Custom') {
        if (_customStartDate != null && _customEndDate != null) {
          return (dateOnly.isAfter(_customStartDate!) || dateOnly.isAtSameMomentAs(_customStartDate!)) &&
                 (dateOnly.isBefore(_customEndDate!) || dateOnly.isAtSameMomentAs(_customEndDate!));
        }
        return true;
      }
      return true;
    }).toList();
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC0392B), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = 'Custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    } else {
      // Revert if cancelled
      if (_selectedFilter == 'Custom' && _customStartDate == null) {
        setState(() {
          _selectedFilter = 'Today';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Business Insight', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Today'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 7 Days'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 15 Days'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Custom', onTap: _selectCustomDateRange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  _buildStatsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, {VoidCallback? onTap}) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC0392B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFC0392B) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final bookings = _filteredBookings;
    
    // Calculations
    final totalOrder = bookings.length;
    
    // Today orders within the filtered list
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayOrder = bookings.where((b) {
      DateTime? bDate;
      if (b.createdAt.isNotEmpty) {
        bDate = _parseDate(b.createdAt);
      }
      if (bDate == null && b.bookingDate.isNotEmpty) {
        bDate = _parseDate(b.bookingDate);
      }
      if (bDate == null && b.checkIn.isNotEmpty) {
        bDate = _parseDate(b.checkIn);
      }
      if (bDate == null) return false;
      return DateTime(bDate.year, bDate.month, bDate.day).isAtSameMomentAs(today);
    }).length;

    double sumTotalAmount = 0.0;
    double sumPlatformFee = 0.0;
    double sumPayableAmount = 0.0;
    double sumGstAmount = 0.0;

    for (var b in bookings) {
      double basePrice = b.totalAmount > 0 
          ? b.totalAmount 
          : (b.pricePerNight > 0 
              ? b.pricePerNight 
              : (b.totalPayable > 0 ? (b.totalPayable / 1.18) : 0.0));

      if (basePrice > 100 && b.totalPayable > 0 && b.totalPayable <= basePrice * 1.25) {
        basePrice = b.totalPayable / 1.18;
      }

      double customerTotal = (basePrice * 1.18 * 100).roundToDouble() / 100.0;
      if (b.totalPayable > 0) customerTotal = b.totalPayable;

      // Cut 18% GST from customer payment to get base room price
      if (customerTotal > 0 && (basePrice <= 0 || (customerTotal / 1.18 - basePrice).abs() > 2.0)) {
        basePrice = ((customerTotal / 1.18) * 100).roundToDouble() / 100.0;
      }

      // Total 18% GST cut from user payment
      double totalGst = ((customerTotal - basePrice) > 0 ? (customerTotal - basePrice) : (basePrice * 0.18));
      totalGst = (totalGst * 100).roundToDouble() / 100.0;

      // Platform Fee: 34% of base room price (Cut 18% GST)
      double platformFeeNet = ((basePrice * 0.34) * 100).roundToDouble() / 100.0;

      // Owner Final Payable Payout: 66% of base price (Cut 18% GST and platform fee)
      double ownerFinalPayout = ((basePrice * 0.66) * 100).roundToDouble() / 100.0;

      sumTotalAmount += customerTotal;
      sumPlatformFee += platformFeeNet;
      sumPayableAmount += ownerFinalPayout;
      sumGstAmount += totalGst;
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5, // To make them look like rectangles
      children: [
        _buildStatCard('TOTAL ORDER', totalOrder.toString(), const Color(0xFF1ABC9C)), // Green
        _buildStatCard('TODAY ORDER', todayOrder.toString(), const Color(0xFF673AB7)), // Purple
        _buildStatCard('TOTAL AMOUNT', sumTotalAmount.toStringAsFixed(2), const Color(0xFF03A9F4)), // Blue
        _buildStatCard('PLATFORM FEE (34%)', sumPlatformFee.toStringAsFixed(2), const Color(0xFFFF9800)), // Orange
        _buildStatCard('PAYABLE AMOUNT', sumPayableAmount.toStringAsFixed(2), const Color(0xFF00BCD4)), // Cyan
        _buildStatCard('GST AMOUNT (18%)', sumGstAmount.toStringAsFixed(2), const Color(0xFFE91E63)), // Pink
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
