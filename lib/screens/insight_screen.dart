import 'package:flutter/material.dart';
import '../core/models/booking_model.dart';
import '../services/booking_service.dart';
import '../core/utils/date_formatter.dart';
import '../widgets/yaan_ui.dart';

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
      backgroundColor: YaanColors.ground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Container(
          decoration: const BoxDecoration(
            color: YaanColors.navy,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: const SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Business Insight',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: YaanColors.brand))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 16),

                  // Stats
                  _buildStatsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, {VoidCallback? onTap}) {
    final isSelected = _selectedFilter == label;
    return Material(
      color: isSelected ? YaanColors.brand : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? YaanColors.brand : YaanColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'Custom') ...[
                Icon(Icons.calendar_today_outlined, size: 14, color: isSelected ? Colors.white : YaanColors.ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : YaanColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
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

    // Split bar parts (same numbers as before, shown as one bar + list)
    const payoutColor = Color(0xFF2A78D6);
    const feeColor = Color(0xFFEB6834);
    const gstColor = Color(0xFF1BAF7A);
    final splitTotal = sumPayableAmount + sumPlatformFee + sumGstAmount;
    int share(double v) => splitTotal > 0 ? ((v / splitTotal) * 1000).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YaanCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Payable amount (your payout)', style: TextStyle(color: YaanColors.muted, fontSize: 13)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${sumPayableAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: YaanColors.ink, fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: -1),
                ),
              ),
              Text(
                '66% of room price · from $totalOrder ${totalOrder == 1 ? 'order' : 'orders'}',
                style: const TextStyle(color: YaanColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (splitTotal > 0)
                Semantics(
                  label: 'Total paid by drivers ₹${sumTotalAmount.toStringAsFixed(2)}: '
                      'your payout ₹${sumPayableAmount.toStringAsFixed(2)}, '
                      'platform fee ₹${sumPlatformFee.toStringAsFixed(2)}, '
                      'GST ₹${sumGstAmount.toStringAsFixed(2)}',
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        _barPart(share(sumPayableAmount), payoutColor),
                        const SizedBox(width: 2),
                        _barPart(share(sumPlatformFee), feeColor),
                        const SizedBox(width: 2),
                        _barPart(share(sumGstAmount), gstColor),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              _legendRow(payoutColor, 'Your payout', sumPayableAmount),
              const SizedBox(height: 10),
              _legendRow(feeColor, 'Platform fee (34%)', sumPlatformFee),
              const SizedBox(height: 10),
              _legendRow(gstColor, 'GST amount (18%)', sumGstAmount),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFE4E7EC)),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text('Total amount paid by drivers', style: TextStyle(color: YaanColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    '₹${sumTotalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: YaanColors.ink, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Total orders', totalOrder.toString(), Icons.receipt_long_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Today orders', todayOrder.toString(), Icons.schedule_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _barPart(int flex, Color color) {
    if (flex <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    );
  }

  Widget _legendRow(Color color, String label, double value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: YaanColors.body, fontSize: 13))),
        Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(color: YaanColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return YaanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: YaanColors.ground, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: YaanColors.ink),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: YaanColors.muted, fontSize: 12)),
          Text(value, style: const TextStyle(color: YaanColors.ink, fontSize: 26, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
