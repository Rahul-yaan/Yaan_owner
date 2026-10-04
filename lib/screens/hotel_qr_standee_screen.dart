import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hotel_service.dart';

class HotelQrStandeeScreen extends StatefulWidget {
  const HotelQrStandeeScreen({super.key});

  @override
  State<HotelQrStandeeScreen> createState() => _HotelQrStandeeScreenState();
}

class _HotelQrStandeeScreenState extends State<HotelQrStandeeScreen> {
  final HotelService _hotelService = HotelService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _standeeData;

  @override
  void initState() {
    super.initState();
    _fetchStandee();
  }

  Future<void> _fetchStandee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _hotelService.getHotelQrStandee();
      if (mounted) {
        setState(() {
          _standeeData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
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
      ),
    );
  }

  Future<void> _openQrImage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open QR code image URL')),
        );
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
        title: const Text('Hotel QR Standee', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStandee,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Color(0xFFC0392B)),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchStandee,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildStandeeContent(),
    );
  }

  Widget _buildStandeeContent() {
    final hotelName = _standeeData?['hotel_name'] ?? 'Your Hotel';
    final yaanId = _standeeData?['yaan_id'] ?? _standeeData?['hotel_code'] ?? 'YAAN';
    final city = _standeeData?['city'] ?? '';
    final qrUrl = _standeeData?['qr_code_url'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Acrylic Counter Standee Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Brand Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC0392B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'YAAN OFFICIAL PARTNER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Instant Spot Booking Standee',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Hotel Name
                      Text(
                        hotelName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          city,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Yaan Hotel ID Badge
                      InkWell(
                        onTap: () => _copyToClipboard(yaanId, 'Hotel ID'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'HOTEL ID: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                yaanId,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC0392B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, size: 16, color: Color(0xFFC0392B)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // High Resolution QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: qrUrl.isNotEmpty
                            ? Image.network(
                                qrUrl,
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(color: Color(0xFFC0392B)),
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, err, stack) => const SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Center(
                                    child: Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                                  ),
                                ),
                              )
                            : const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                                ),
                              ),
                      ),

                      const SizedBox(height: 18),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            'Scan with Yaan User App to Book',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFC0392B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How to use this Standee',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '1. Print or download this QR code and display it at your front desk reception.\n'
                  '2. Truck drivers and travelers can point their Yaan app camera to book on the spot.\n'
                  '3. All payments and bookings will instantly show up in your Bookings tab.',
                  style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          if (qrUrl.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openQrImage(qrUrl),
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  'Open Full QR Image / Print',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard(yaanId, 'Hotel ID'),
              icon: const Icon(Icons.copy, color: Color(0xFFC0392B)),
              label: const Text(
                'Copy Hotel ID',
                style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC0392B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
