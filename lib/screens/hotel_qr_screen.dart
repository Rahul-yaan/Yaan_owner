import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/hotel_service.dart';

class HotelQrScreen extends StatefulWidget {
  final int? hotelId;
  const HotelQrScreen({super.key, this.hotelId});

  @override
  State<HotelQrScreen> createState() => _HotelQrScreenState();
}

class _HotelQrScreenState extends State<HotelQrScreen> {
  final HotelService _hotelService = HotelService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _qrData;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
  }

  Future<void> _loadQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _hotelService.getHotelQrCode(hotelId: widget.hotelId);
      if (mounted) {
        setState(() {
          _qrData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFC0392B);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Hotel QR Standee', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQrCode,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Generating Hotel QR Poster...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: primaryColor, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadQrCode,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPosterContent(),
    );
  }

  Widget _buildPosterContent() {
    final hotelName = _qrData?['hotel_name'] ?? _qrData?['hotel']?['name'] ?? 'Hotel';
    final yaanId = _qrData?['yaan_id'] ?? _qrData?['hotel_code'] ?? 'YAAN';
    final city = _qrData?['city'] ?? _qrData?['hotel']?['city'] ?? '';
    final address = _qrData?['address'] ?? _qrData?['hotel']?['address'] ?? '';
    final qrPayload = _qrData?['qr_payload'] ?? yaanId;
    final List instructions = _qrData?['instructions'] ?? [
      '1. Download and print this QR poster standee.',
      '2. Place this poster at your Hotel Reception or Entry Gate.',
      '3. Drivers can scan this QR code using their Yaan User App for instant spot booking.',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // STANDEE CARD MOCKUP
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC0392B), Color(0xFF962D22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'OFFICIAL YAAN PARTNER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hotelName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (city.isNotEmpty || address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [address, city].where((e) => e.toString().isNotEmpty).join(', '),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                // QR Code Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'SCAN & SPOT BOOK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Truck Drivers can scan with Yaan App to book',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),

                      // QR Code Frame
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 210,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1E293B)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E293B)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // YAAN ID BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('HOTEL YAAN ID', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  yaanId,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC0392B), letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _copyToClipboard(yaanId, 'YAAN ID'),
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFFC0392B), size: 20),
                              tooltip: 'Copy YAAN ID',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // INSTRUCTIONS CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How Hotel QR Standee Works',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...instructions.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF27AE60), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.toString(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}