import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/hotel_service.dart';
import '../widgets/yaan_ui.dart';

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

  Future<void> _shareHotelDetails() async {
    final hotelName = _qrData?['hotel_name'] ?? _qrData?['hotel']?['name'] ?? 'Hotel';
    final yaanId = _qrData?['yaan_id'] ?? _qrData?['hotel_code'] ?? 'YAAN';
    final city = _qrData?['city'] ?? _qrData?['hotel']?['city'] ?? '';
    final address = _qrData?['address'] ?? _qrData?['hotel']?['address'] ?? '';
    final locationText = [address, city].where((e) => e.toString().trim().isNotEmpty).join(', ');

    final shareText = '🏨 Book Your Stay at $hotelName\n'
        '${locationText.isNotEmpty ? '📍 Location: $locationText\n' : ''}'
        '🆔 Hotel YAAN ID: $yaanId\n\n'
        '📲 Truck Drivers can scan our Hotel QR code or enter YAAN ID $yaanId using the Yaan User App for instant spot booking!';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Hotel QR Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share with drivers or transport partners to book via Yaan App',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFFF0FDF4),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.chat_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('Share on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Send hotel YAAN ID and booking info', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  final webUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFFF8FAFC),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(Icons.copy_rounded, color: Color(0xFF0F172A)),
              ),
              title: const Text('Copy Hotel Details & YAAN ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Copy full message to paste anywhere', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(shareText, 'Hotel details');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = YaanColors.brand;

    return Scaffold(
      backgroundColor: YaanColors.ground,
      appBar: AppBar(
        title: const Text('Hotel QR Standee', style: TextStyle(color: YaanColors.ink, fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: YaanColors.ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(child: YaanBackButton()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: _shareHotelDetails,
            tooltip: 'Share QR Details',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadQrCode,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster preview
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: YaanColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Red band with hotel name
                Container(
                  color: YaanColors.brand,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'OFFICIAL YAAN PARTNER',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hotelName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                      if (city.isNotEmpty || address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [address, city].where((e) => e.toString().isNotEmpty).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFFFF1EF), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),

                // QR body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'SCAN & SPOT BOOK',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1, color: YaanColors.ink),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Truck drivers can scan with the Yaan app to book',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: YaanColors.muted),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE4E7EC)),
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: YaanColors.navy),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: YaanColors.navy),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // YAAN ID
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: YaanColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'HOTEL YAAN ID',
                                    style: TextStyle(fontSize: 10, color: YaanColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                                  ),
                                  Text(
                                    yaanId,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: YaanColors.brand, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: YaanColors.brandTint,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _copyToClipboard(yaanId, 'YAAN ID'),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.copy_rounded, color: YaanColors.brand, size: 18, semanticLabel: 'Copy YAAN ID'),
                                ),
                              ),
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
          const SizedBox(height: 14),
          YaanPrimaryButton(
            text: 'Share Hotel QR Details',
            icon: Icons.share_rounded,
            onPressed: _shareHotelDetails,
          ),
          const SizedBox(height: 14),

          // How it works
          YaanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: YaanColors.amber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'How the hotel QR standee works',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: YaanColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: YaanColors.navy, shape: BoxShape.circle),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              // Server steps already start with "1. ", so drop that number here
                              entry.value.toString().replaceFirst(RegExp(r'^\s*\d+\.\s*'), ''),
                              style: const TextStyle(fontSize: 13, color: YaanColors.body, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}