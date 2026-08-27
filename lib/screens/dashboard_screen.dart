import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/profile_service.dart';
import 'hotel_setup_screen.dart';
import 'booking_details_screen.dart';
import 'insight_screen.dart';
import 'account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final ProfileService _profileService = ProfileService();
  int _currentIndex = 0;

  String? _kycStatus;
  String? _rejectionReason;
  String? _kycMessage;
  String? _hotelStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    try {
      final res = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _kycStatus = res['kyc_status'];
          _rejectionReason = res['rejection_reason'];
          _kycMessage = res['kyc_message'];
          _hotelStatus = res['hotel_status'];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFC0392B);
    const Color primaryDark = Color(0xFFA62A1B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(124.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'All Bookings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: primaryColor,
                            unselectedLabelColor: Colors.white.withValues(alpha: 0.9),
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            tabs: const [
                              Tab(text: 'TODAY'),
                              Tab(text: 'OLDER'),
                              Tab(text: 'UPCOMING'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 12,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Insight'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Past Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return TabBarView(
          controller: _tabController,
          children: [
            _buildBookingList('today'),
            _buildBookingList('older'),
            _buildBookingList('upcoming'),
          ],
        );
      case 1:
        return const InsightScreen();
      case 2:
        return _buildBookingList('older');
      case 3:
        return const AccountScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBookingList(String filter) {
    return StatefulBuilder(
      builder: (context, setState) {
        return RefreshIndicator(
          color: const Color(0xFFC0392B),
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Column(
            children: [
              _buildKycNotificationCard(),
              Expanded(
                child: FutureBuilder<List<BookingModel>>(
                  future: _bookingService.getBookings(filter: filter),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B)));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No bookings found. Pull down to refresh.',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final bookings = snapshot.data!;
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingCard(booking, filter);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

    Widget _buildKycNotificationCard() {
    if (_kycStatus == null && _rejectionReason == null && _hotelStatus == null) {
      return const SizedBox();
    }

    final isRejected = _kycStatus == 'rejected' ||
        _hotelStatus == 'rejected' ||
        (_rejectionReason != null && _rejectionReason!.trim().isNotEmpty);

    final isPending = _kycStatus == 'pending_approval' ||
        _kycStatus == 'pending' ||
        _hotelStatus == 'pending';

    final isApproved = (_kycStatus == 'approved' || _kycStatus == 'active') &&
        (_hotelStatus == 'approved' || _hotelStatus == 'active');

    if (isApproved) return const SizedBox();

    final Color bgColor = isRejected
        ? const Color(0xFFFEF2F2)
        : (isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4));

    final Color borderColor = isRejected
        ? const Color(0xFFFCA5A5)
        : (isPending ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC));

    final Color iconColor = isRejected
        ? const Color(0xFFDC2626)
        : (isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A));

    final String titleText = isRejected
        ? 'Application Rejected by Admin'
        : (isPending ? 'Approval Pending' : 'KYC Approved');

    final String displayReason = (_rejectionReason != null && _rejectionReason!.trim().isNotEmpty)
        ? _rejectionReason!
        : (_kycMessage ?? 'Admin rejected your application.');

    final String bodyMessage = isRejected
        ? 'Your application was rejected due to: $displayReason'
        : (_kycMessage ?? 'Please wait for approval by the admin.');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRejected
                ? Icons.error_outline_rounded
                : (isPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded),
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bodyMessage,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isRejected
                        ? const Color(0xFF991B1B)
                        : (isPending ? const Color(0xFF92400E) : const Color(0xFF166534)),
                    fontWeight: isRejected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isRejected) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HotelSetupScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Update & Resubmit Application',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: iconColor),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, String filter) {
    const Color primaryColor = Color(0xFFC0392B);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingDetailsScreen(booking: booking)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Booking ID & Status Dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Booking ID : ${booking.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                        SizedBox(width: 5),
                        Text(
                          "Confirmed",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // User Name Row with Avatar Initial
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      booking.userName.isNotEmpty ? booking.userName.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Name',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        booking.userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vehicle & Slot Details Container Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          '${booking.truckType} | ${booking.truckNo}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Divider(height: 14, thickness: 0.8, color: Color(0xFFE2E8F0)),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Slot : ${booking.displaySlot}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\u{20B9} ${booking.totalAmount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookingDetailsScreen(booking: booking)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('VIEW DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (filter == 'older')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRatingDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text('VIEW RATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(booking.userPhone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.phone_in_talk, size: 16),
                        label: const Text('CALL NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('View Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => const Icon(Icons.star, color: Colors.amber, size: 32))
                  ..add(const Icon(Icons.star_border, color: Colors.amber, size: 32)),
              ),
              const SizedBox(height: 8),
              const Text('Good', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              const Text(
                'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Center(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
