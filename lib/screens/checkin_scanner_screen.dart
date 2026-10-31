import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_service.dart';
import '../core/models/booking_model.dart';
import '../widgets/yaan_ui.dart';
import 'booking_details_screen.dart';

class CheckInScannerScreen extends StatefulWidget {
  const CheckInScannerScreen({super.key});

  @override
  State<CheckInScannerScreen> createState() => _CheckInScannerScreenState();
}

class _CheckInScannerScreenState extends State<CheckInScannerScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _animation;
  final BookingService _bookingService = BookingService();

  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _handleScannedCode(rawValue.trim());
        break;
      }
    }
  }

  int? _extractBookingId(String code, {bool manual = false}) {
    final value = code.trim();
    // The customer app's check-in pass contains exactly "YAAN-BOOKING-<id>".
    // Any other scanned QR (truck numbers, hotel QR, random codes) is not a booking.
    final match = RegExp(r'^YAAN-BOOKING-(\d+)$', caseSensitive: false).firstMatch(value);
    if (match != null) return int.tryParse(match.group(1)!);
    // Typed in "Search Booking": a plain booking number is allowed (10-digit phones are not IDs)
    if (manual && RegExp(r'^\d{1,9}$').hasMatch(value)) return int.tryParse(value);
    return null;
  }

  // Manual search only: exact truck number or driver phone among this owner's bookings
  Future<BookingModel?> _findByTruckOrPhone(String input) async {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String last10(String s) {
      final d = s.replaceAll(RegExp(r'\D'), '');
      return d.length >= 10 ? d.substring(d.length - 10) : '';
    }

    final query = norm(input);
    final phone = last10(input);
    if (query.length < 4) return null;

    final allBookings = await _bookingService.getBookings(filter: 'all');
    final matches = allBookings.where((b) {
      if (norm(b.truckNo) == query) return true;
      if (phone.isEmpty) return false;
      return last10((b.user?['phone'] ?? '').toString()) == phone || last10(b.logisticsNumber) == phone;
    }).toList();
    if (matches.isEmpty) return null;

    // Several bookings for the same truck/phone: show the one waiting for check-in first
    return matches.firstWhere((b) => b.status.toLowerCase() == 'confirmed', orElse: () => matches.first);
  }

  Future<void> _handleScannedCode(String rawCode, {bool manual = false}) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFC0392B)),
                SizedBox(height: 16),
                Text('Verifying Booking...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Searching driver check-in details', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final bookingId = _extractBookingId(rawCode, manual: manual);
      BookingModel? foundBooking;

      if (bookingId != null) {
        try {
          // Backend only returns bookings of this owner's hotel
          foundBooking = await _bookingService.getBookingDetails(bookingId);
        } catch (_) {}
      }

      if (foundBooking == null && manual) {
        foundBooking = await _findByTruckOrPhone(rawCode);
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (!mounted) return;

      if (foundBooking != null) {
        _showBookingCheckInModal(foundBooking);
      } else {
        _showNotFoundDialog(rawCode);
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        _showNotFoundDialog(rawCode, errorMsg: e.toString());
      }
    }
  }

  void _showBookingCheckInModal(BookingModel booking) {
    final driverName = booking.user?['name'] ?? 'Driver';
    final driverPhone = booking.user?['phone'] ?? '';
    // completed = driver already checked in, confirmed = paid / pay-at-hotel booking ready for check-in
    final status = booking.status.toLowerCase();
    final isCheckedIn = status == 'completed';
    final canCheckIn = status == 'confirmed';
    final String statusLabel = isCheckedIn
        ? 'CHECKED IN'
        : canCheckIn
            ? 'READY FOR CHECK-IN'
            : status == 'cancelled'
                ? 'CANCELLED'
                : 'PAYMENT PENDING';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final Color chipFg = isCheckedIn
              ? YaanColors.blueText
              : (canCheckIn ? YaanColors.greenText : (status == 'cancelled' ? YaanColors.body : YaanColors.amberText));
          final Color chipBg = isCheckedIn
              ? YaanColors.blueTint
              : (canCheckIn ? YaanColors.greenTint : (status == 'cancelled' ? const Color(0xFFF1F2F4) : YaanColors.amberTint));

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YaanColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCheckedIn || canCheckIn ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                            size: 14,
                            color: chipFg,
                          ),
                          const SizedBox(width: 6),
                          Text(statusLabel, style: TextStyle(color: chipFg, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.6)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('Booking #${booking.id}', style: const TextStyle(fontSize: 12, color: YaanColors.muted)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: YaanColors.navy, shape: BoxShape.circle),
                      child: Text(
                        yaanInitials(driverName.toString()),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: YaanColors.ink),
                          ),
                          if (driverPhone.isNotEmpty)
                            Text(driverPhone, style: const TextStyle(color: YaanColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (driverPhone.isNotEmpty)
                      Material(
                        color: YaanColors.greenTint,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Call driver',
                          icon: const Icon(Icons.phone_outlined, color: YaanColors.green, size: 20),
                          onPressed: () => launchUrl(Uri.parse('tel:$driverPhone')),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Booking details grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDetailItem('TRUCK NUMBER', booking.truckNo.isNotEmpty ? booking.truckNo : 'Not Specified')),
                          Expanded(child: _buildDetailItem('TRUCK TYPE', booking.truckType.isNotEmpty ? booking.truckType : 'Standard')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildDetailItem('BOOKING DATE', booking.bookingDate.isNotEmpty ? booking.bookingDate : booking.checkIn)),
                          Expanded(
                            child: _buildDetailItem(
                              'TOTAL PAYABLE',
                              '₹${booking.totalPayable > 0 ? booking.totalPayable.toStringAsFixed(2) : booking.totalAmount.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: YaanColors.ink,
                          side: const BorderSide(color: YaanColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Full Details', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: !canCheckIn
                            ? null
                            : () async {
                                try {
                                  // Check-in marks the booking completed (pay-at-hotel cash is marked paid by the server)
                                  final success = await _bookingService.updateBookingStatus(booking.id, 'completed');
                                  if (success && mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Driver Checked In Successfully!'),
                                        backgroundColor: Color(0xFF27AE60),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(isCheckedIn ? Icons.check : Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                        label: Text(
                          isCheckedIn ? 'Already Checked In' : (canCheckIn ? 'Confirm Check-In' : statusLabel),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCheckIn ? YaanColors.green : const Color(0xFF94A3B8),
                          disabledBackgroundColor: const Color(0xFF94A3B8),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: YaanColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YaanColors.ink)),
      ],
    );
  }

  void _showNotFoundDialog(String code, {String? errorMsg}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_off_rounded, color: Color(0xFFC0392B)),
            SizedBox(width: 8),
            Text('Booking Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          errorMsg ?? 'No matching booking found for code: "$code". Please verify booking number or search by phone/truck number.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Scan Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showManualSearchDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_rounded, color: Color(0xFFC0392B)),
            SizedBox(width: 8),
            Text('Search Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Booking ID, Driver Phone, or Truck Number',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 12 or MH12AB1234',
                prefixIcon: const Icon(Icons.pin, color: Color(0xFFC0392B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final code = textController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _handleScannedCode(code, manual: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scanWindowSize = MediaQuery.of(context).size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Cutout overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Frame border & Laser
          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value * (scanWindowSize - 10),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Driver Check-In',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? Colors.amber : Colors.white,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _scannerController.toggleTorch();
                            setState(() => _isFlashOn = !_isFlashOn);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                          onPressed: () async {
                            await _scannerController.switchCamera();
                            setState(() => _isFrontCamera = !_isFrontCamera);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Color(0xFF27AE60), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Scan driver booking pass or QR to check in',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _showManualSearchDialog,
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    label: const Text(
                      'Search by booking ID, phone or truck',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YaanColors.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}