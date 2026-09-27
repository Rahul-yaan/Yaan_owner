import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_service.dart';
import '../core/models/booking_model.dart';
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

  int? _extractBookingId(String code) {
    // 1. Direct integer
    if (int.tryParse(code) != null) {
      return int.parse(code);
    }
    // 2. YAAN-BOOKING-12 or BOOK-12
    final match = RegExp(r'(?:YAAN-BOOKING-|BOOK-|BOOKING-)?(\d+)').firstMatch(code);
    if (match != null && match.group(1) != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  Future<void> _handleScannedCode(String rawCode) async {
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
      final bookingId = _extractBookingId(rawCode);
      BookingModel? foundBooking;

      if (bookingId != null) {
        try {
          foundBooking = await _bookingService.getBookingDetails(bookingId);
        } catch (_) {}
      }

      // If not found by direct ID, search in all bookings
      if (foundBooking == null) {
        final allBookings = await _bookingService.getBookings(filter: 'all');
        final cleanRaw = rawCode.toLowerCase().trim();
        for (final b in allBookings) {
          if (b.id.toString() == cleanRaw ||
              b.truckNo.toLowerCase().contains(cleanRaw) ||
              b.logisticsNumber.toLowerCase().contains(cleanRaw) ||
              (b.user?['phone'] ?? '').toString().contains(cleanRaw)) {
            foundBooking = b;
            break;
          }
        }
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
    final isConfirmed = booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isConfirmed ? 'CHECKED IN' : 'READY FOR CHECK-IN',
                        style: TextStyle(
                          color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      'Booking #${booking.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  driverName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                if (driverPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Color(0xFF27AE60)),
                      const SizedBox(width: 6),
                      Text(driverPhone, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('tel:$driverPhone')),
                        child: const Text('Call', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Booking details grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('TRUCK NUMBER', booking.truckNo.isNotEmpty ? booking.truckNo : 'Not Specified'),
                          _buildDetailItem('TRUCK TYPE', booking.truckType.isNotEmpty ? booking.truckType : 'Standard'),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('BOOKING DATE', booking.bookingDate.isNotEmpty ? booking.bookingDate : booking.checkIn),
                          _buildDetailItem('TOTAL PAYABLE', '₹${booking.totalPayable > 0 ? booking.totalPayable.toStringAsFixed(2) : booking.totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Full Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isConfirmed
                            ? null
                            : () async {
                                final success = await _bookingService.updateBookingStatus(booking.id, 'confirmed');
                                if (success) {
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Driver Checked In Successfully! Booking Confirmed.'),
                                        backgroundColor: Color(0xFF27AE60),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(isConfirmed ? Icons.check : Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                        label: Text(
                          isConfirmed ? 'Already Confirmed' : 'CONFIRM CHECK-IN',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConfirmed ? const Color(0xFF94A3B8) : const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                _handleScannedCode(code);
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
                    'Driver Check-In Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showManualSearchDialog,
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    label: const Text(
                      'Search by Booking ID / Phone / Truck',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
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