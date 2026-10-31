import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/booking_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  // Colours shared with the new design
  static const Color _brand = Color(0xFFC0392B);
  static const Color _navy = Color(0xFF1B2433);
  static const Color _ink = Color(0xFF14181F);
  static const Color _body = Color(0xFF475467);
  static const Color _muted = Color(0xFF5B6472);
  static const Color _line = Color(0xFFEEF0F3);
  static const Color _ground = Color(0xFFF4F5F7);
  static const Color _green = Color(0xFF157F3D);

  bool _breakfastCompleted = true;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String get _initials {
    final parts = widget.booking.userName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // Status chip text and colours
  ({String label, Color fg, Color bg}) get _statusStyle {
    switch (widget.booking.status.toLowerCase()) {
      case 'confirmed':
        return (label: 'Confirmed', fg: const Color(0xFF0F5A2B), bg: const Color(0xFFE8F6EE));
      case 'completed':
        return (label: 'Checked in', fg: const Color(0xFF1D4E89), bg: const Color(0xFFE6EEF9));
      case 'cancelled':
        return (label: 'Cancelled', fg: _body, bg: const Color(0xFFF1F2F4));
      case 'pending':
        return (label: 'Pending', fg: const Color(0xFF7A4505), bg: const Color(0xFFFEF4E2));
      default:
        final s = widget.booking.status;
        return (
          label: s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1),
          fg: _body,
          bg: const Color(0xFFF1F2F4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    // Payment details: the same amounts the driver saw and paid (saved by the server)
    final double roomPrice = booking.pricePerNight;   // room price before offer and GST
    final double offer = booking.discount;            // offer / coupon discount (0 when none)
    final double gst = booking.gst;                   // 18% GST paid by the driver
    final double totalPayable = booking.totalPayable; // what the driver paid in total

    final status = _statusStyle;

    return Scaffold(
      backgroundColor: _ground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: _ground,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back, color: _ink, size: 20, semanticLabel: 'Back'),
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Detail',
              style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              'Booking #${booking.id}',
              style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: status.fg, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  status.label,
                  style: TextStyle(color: status.fg, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User details
            _card(
              title: 'User details',
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle),
                      child: Text(
                        _initials,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.userName,
                            style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          if (booking.userPhone.isNotEmpty)
                            Text(
                              booking.userPhone,
                              style: const TextStyle(color: _muted, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(booking.userPhone),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Call Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Breakfast toggle (same behaviour as before)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _cardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF4E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.free_breakfast_outlined, color: Color(0xFFA15C07), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Breakfast completed',
                      style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _breakfastCompleted,
                    activeTrackColor: _green,
                    thumbColor: const WidgetStatePropertyAll(Colors.white),
                    onChanged: (val) {
                      setState(() {
                        _breakfastCompleted = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Booking details
            _card(
              title: 'Booking details',
              children: [
                _infoRow('Slot', booking.displaySlot),
                _divider(),
                _infoRow('Truck type', booking.truckType),
                _divider(),
                _infoRow('Truck no', booking.truckNo),
                _divider(),
                _infoRow('Logistics name', booking.logisticsName),
                _divider(),
                _infoRow('Logistics number', booking.logisticsNumber),
              ],
            ),
            const SizedBox(height: 14),

            // Payment details: total amount, offer (only when applied), GST, total payable
            _card(
              title: 'Payment details',
              children: [
                _moneyRow('Total amount', _money(roomPrice)),
                if (offer > 0) ...[
                  const SizedBox(height: 12),
                  _moneyRow('Offer applied', '-${_money(offer)}', valueColor: _green),
                ],
                const SizedBox(height: 12),
                _moneyRow('GST (18%)', _money(gst)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE4E7EC)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Total payable amount',
                        style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _money(totalPayable),
                      style: const TextStyle(color: _green, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: _line),
      );

  Widget _moneyRow(String label, String value, {Color valueColor = _ink}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: _body, fontSize: 13))),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
