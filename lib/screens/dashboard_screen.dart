import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/profile_service.dart';
import '../widgets/yaan_ui.dart';
import 'hotel_setup_screen.dart';
import 'booking_details_screen.dart';
import 'checkin_scanner_screen.dart';
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
  String? _hotelName;
  String? _ownerName;

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
          _hotelName = (res['hotel'] is Map ? res['hotel']['name'] : null)?.toString() ??
              (res['profile'] is Map ? res['profile']['hotel_name'] : null)?.toString();
          _ownerName = (res['user'] is Map ? res['user']['name'] : null)?.toString();
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

  // Same rules as before for reading the approval state
  bool get _isRejected =>
      _kycStatus == 'rejected' ||
      _hotelStatus == 'rejected' ||
      (_rejectionReason != null && _rejectionReason!.trim().isNotEmpty);

  bool get _isPending => _kycStatus == 'pending_approval' || _kycStatus == 'pending' || _hotelStatus == 'pending';

  bool get _isApproved =>
      (_kycStatus == 'approved' || _kycStatus == 'active') && (_hotelStatus == 'approved' || _hotelStatus == 'active');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaanColors.ground,
      appBar: _currentIndex == 0
          ? _navyHeader(title: 'All Bookings', withTabs: true)
          : (_currentIndex == 2 ? _navyHeader(title: 'Past Bookings', withTabs: false) : null),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: YaanColors.brandTint,
        height: 68,
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: YaanColors.muted),
            selectedIcon: Icon(Icons.home_rounded, color: YaanColors.brand),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded, color: YaanColors.muted),
            selectedIcon: Icon(Icons.show_chart_rounded, color: YaanColors.brand),
            label: 'Insight',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded, color: YaanColors.muted),
            selectedIcon: Icon(Icons.history_rounded, color: YaanColors.brand),
            label: 'Past',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: YaanColors.muted),
            selectedIcon: Icon(Icons.person_rounded, color: YaanColors.brand),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _navyHeader({required String title, required bool withTabs}) {
    return PreferredSize(
      preferredSize: Size.fromHeight(withTabs ? 132 : 84),
      child: Container(
        decoration: const BoxDecoration(
          color: YaanColors.navy,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_hotelName ?? '').isNotEmpty)
                            Text(
                              _hotelName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: YaanColors.headerSub, fontSize: 12),
                            ),
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Notifications',
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                if (withTabs) ...[
                  const SizedBox(height: 14),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      labelColor: YaanColors.brand,
                      unselectedLabelColor: const Color(0xFFE6EAF0),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'Older'),
                        Tab(text: 'Upcoming'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
          color: YaanColors.brand,
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
          },
          child: FutureBuilder<List<BookingModel>>(
            future: _bookingService.getBookings(filter: filter),
            builder: (context, snapshot) {
              // Cards shown above the bookings: approval status + driver check-in
              final header = <Widget>[
                _buildKycNotificationCard(),
                if (filter != 'older' && !_isPending && !_isRejected) _buildCheckInCard(),
              ];

              Widget body;
              if (snapshot.connectionState == ConnectionState.waiting) {
                body = const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: YaanColors.brand)),
                );
              } else if (snapshot.hasError) {
                body = Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                body = SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.inbox_outlined, size: 30, color: Color(0xFF9AA4B1)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No bookings found. Pull down to refresh.',
                          style: TextStyle(fontSize: 14, color: YaanColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                body = Column(
                  children: snapshot.data!.map((booking) => _buildBookingCard(booking, filter)).toList(),
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [...header, body],
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Approval status (pending / rejected / approved), same rules as before
  // ---------------------------------------------------------------------------
  Widget _buildKycNotificationCard() {
    if (_kycStatus == null && _rejectionReason == null && _hotelStatus == null) {
      return const SizedBox();
    }
    if (_isApproved) return const SizedBox();

    if (_isRejected) return _rejectedCard();
    if (_isPending) return _pendingCard();

    // Neither pending nor rejected: small green note (same as before)
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: YaanColors.greenTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFE5CD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: YaanColors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'KYC Approved', style: TextStyle(fontWeight: FontWeight.w600)),
                    if ((_kycMessage ?? '').isNotEmpty) TextSpan(text: ' · $_kycMessage'),
                  ],
                ),
                style: const TextStyle(color: YaanColors.greenText, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard() {
    final name = (_ownerName ?? '').trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YaanCard(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: YaanColors.amberTint, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_top_rounded, color: YaanColors.amber, size: 34),
                ),
                const SizedBox(height: 10),
                const YaanStatusChip(label: 'UNDER REVIEW', fg: YaanColors.amberText, bg: YaanColors.amberTint, dot: false),
                const SizedBox(height: 10),
                const Text(
                  'Waiting for admin approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: YaanColors.ink, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  (_kycMessage ?? '').isNotEmpty
                      ? _kycMessage!
                      : '${name.isNotEmpty ? 'Thanks, $name! ' : ''}Your hotel details were sent. The Yaan admin team is checking your documents now.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: YaanColors.body, fontSize: 13, height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          YaanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Your progress', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                _timelineRow(state: 'done', title: 'Account created', subtitle: 'Mobile number verified'),
                _timelineRow(state: 'done', title: 'Hotel details submitted', subtitle: 'Documents, pricing and bank'),
                _timelineRow(state: 'current', title: 'Admin review', subtitle: 'In progress'),
                _timelineRow(state: 'todo', title: 'Hotel goes live', subtitle: 'Drivers can find and book you', last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          YaanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Until you are approved', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _infoLine(Icons.visibility_off_outlined, 'Your hotel is hidden from drivers in search.'),
                const SizedBox(height: 10),
                _infoLine(Icons.lock_outline_rounded, 'Bookings, Hotel QR standee and payouts unlock after approval.'),
                const SizedBox(height: 14),
                YaanOutlineButton(
                  text: 'Refresh status',
                  icon: Icons.refresh_rounded,
                  height: 46,
                  onPressed: _fetchKycStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedCard() {
    final String displayReason = (_rejectionReason != null && _rejectionReason!.trim().isNotEmpty)
        ? _rejectionReason!
        : (_kycMessage ?? 'Admin rejected your application.');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YaanCard(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: YaanColors.redTint, shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: YaanColors.red, size: 34),
                ),
                const SizedBox(height: 10),
                const YaanStatusChip(label: 'ACTION NEEDED', fg: YaanColors.red, bg: YaanColors.redTint, dot: false),
                const SizedBox(height: 10),
                const Text(
                  'Application Rejected by Admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: YaanColors.ink, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Don't worry, you can fix it. Update your details and send your application again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: YaanColors.body, fontSize: 13, height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          YaanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Reason from admin', style: TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: YaanColors.redTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF8C9C4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: YaanColors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your application was rejected due to: $displayReason',
                          style: const TextStyle(color: Color(0xFF7A1B12), fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                YaanPrimaryButton(
                  text: 'Update & Resubmit Application',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HotelSetupScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow({required String state, required String title, required String subtitle, bool last = false}) {
    final done = state == 'done';
    final current = state == 'current';
    Widget dot;
    if (done) {
      dot = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: YaanColors.green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    } else if (current) {
      dot = Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: YaanColors.amberTint,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD98A0B), width: 2),
        ),
        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFD98A0B), shape: BoxShape.circle)),
      );
    } else {
      dot = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: YaanColors.border, width: 2)),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              dot,
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? YaanColors.green : const Color(0xFFE4E7EC),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: state == 'todo' ? YaanColors.muted : YaanColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: current ? YaanColors.amberText : YaanColors.muted,
                      fontSize: 12,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: YaanColors.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: YaanColors.body, fontSize: 13, height: 1.5))),
      ],
    );
  }

  // Opens the driver check-in scanner (this screen existed but had no button before)
  Widget _buildCheckInCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: YaanColors.brand,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckInScannerScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check in a driver', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text(
                        'Scan their QR pass or search by booking ID',
                        style: TextStyle(color: Color(0xFFFFF1EF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Booking card
  // ---------------------------------------------------------------------------
  Widget _buildBookingCard(BookingModel booking, String filter) {
    final status = yaanBookingStatus(booking.status);

    void openDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookingDetailsScreen(booking: booking)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: openDetails,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: YaanColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Booking #${booking.id}',
                        style: const TextStyle(color: YaanColors.body, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    YaanStatusChip(label: status.label, fg: status.fg, bg: status.bg),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: YaanColors.navy, shape: BoxShape.circle),
                      child: Text(
                        yaanInitials(booking.userName),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: YaanColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${booking.truckType} · ${booking.truckNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: YaanColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Your share', style: TextStyle(color: YaanColors.muted, fontSize: 11)),
                        Text(
                          '₹${booking.ownerNetPayable.toStringAsFixed(2)}',
                          style: const TextStyle(color: YaanColors.ink, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: YaanColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Slot: ${booking.displaySlot}',
                        style: const TextStyle(color: YaanColors.body, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _cardButton(
                        label: 'Details',
                        icon: Icons.info_outline_rounded,
                        onPressed: openDetails,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: filter == 'older'
                          ? _cardButton(
                              label: 'Rating',
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFF2A900),
                              onPressed: _showRatingDialog,
                            )
                          : _cardButton(
                              label: 'Call',
                              icon: Icons.phone_outlined,
                              filled: true,
                              onPressed: () => _makePhoneCall(booking.userPhone),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool filled = false,
    Color? iconColor,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: YaanColors.brand,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: YaanColors.ink,
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: YaanColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
    return filled
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('View Rating', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: YaanColors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => const Icon(Icons.star_rounded, color: Color(0xFFF2A900), size: 32))
                  ..add(const Icon(Icons.star_border_rounded, color: Color(0xFFF2A900), size: 32)),
              ),
              const SizedBox(height: 8),
              const Text('Good', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: YaanColors.ink)),
              const SizedBox(height: 16),
              const Text(
                'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: YaanColors.muted),
              ),
            ],
          ),
          actions: [
            Center(
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, color: YaanColors.ink),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
