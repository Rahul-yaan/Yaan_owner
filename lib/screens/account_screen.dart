import 'hotel_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/models/owner_profile_model.dart';
import '../core/models/user_model.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  OwnerProfileModel? _profile;
  UserModel? _user;
  String? _kycStatus;
  String? _rejectionReason;
  String? _kycMessage;
  String? _hotelStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = data['profile'];
          _user = data['user'];
          _kycStatus = data['kyc_status'];
          _rejectionReason = data['rejection_reason'];
          _kycMessage = data['kyc_message'];
          _hotelStatus = data['hotel_status'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  Future<void> _openLegalPage(String endpoint, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFC0392B)),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('https://yaan-backend.onrender.com/api$endpoint'),
        headers: {
          'Accept': 'application/json',
          'X-App-Type': 'vendor',
        },
      ).timeout(const Duration(seconds: 12));

      if (mounted) Navigator.of(context).pop(); // Dismiss loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String contentText = data['content'] ?? data['description'] ?? 'No information available.';
        final List sections = data['sections'] ?? [];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LegalDetailViewerScreen(
                title: title,
                content: contentText,
                sections: sections,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load page information.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isApproved = (_kycStatus == 'approved' || _kycStatus == 'active') &&
        (_hotelStatus == 'approved' || _hotelStatus == 'active');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKycNotificationCard(),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  const Text('Other Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (isApproved) ...[
                          _buildListTile(Icons.qr_code_2_rounded, 'Hotel QR Standee & Share', () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelQrScreen()));
                          }),
                          _buildDivider(),
                        ],
                        _buildListTile(Icons.description, 'Terms & Conditions', () {
                          _openLegalPage('/vendor/terms-and-conditions', 'Terms & Conditions');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.info_outline, 'About Us', () {
                          _openLegalPage('/vendor/about', 'About Us');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                          _openLegalPage('/vendor/privacy-policy', 'Privacy Policy');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.contact_support_outlined, 'Contact Us', () {
                          _openLegalPage('/vendor/contact', 'Contact Us');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.share_outlined, 'Share App', () {
                          _openLegalPage('/vendor/share', 'Share App');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.image_outlined, 'Add Image', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add Image feature selected.')),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.photo_library_outlined, 'View Gallery', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View Gallery feature selected.')),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.star_outline, 'Rate Us', () {
                          _openLegalPage('/vendor/rate', 'Rate Us');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.help_outline, 'Faq', () {
                          _openLegalPage('/vendor/faq', 'Frequently Asked Questions');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B2B2B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFC0392B).withOpacity(0.1),
            child: Text(
              _profile?.ownerName?.isNotEmpty == true
                  ? _profile!.ownerName.substring(0, 1).toUpperCase()
                  : (_user?.name?.isNotEmpty == true ? _user!.name.substring(0, 1).toUpperCase() : 'U'),
              style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.ownerName?.isNotEmpty == true ? _profile!.ownerName : (_user?.name ?? 'User Name'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? 'user@email.com',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.phone ?? '99999 99999',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black87),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    profile: _profile,
                    user: _user,
                  ),
                ),
              );
              if (result == true) {
                _fetchProfile();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16);
  }
}

class LegalDetailViewerScreen extends StatelessWidget {
  final String title;
  final String content;
  final List sections;

  const LegalDetailViewerScreen({
    super.key,
    required this.title,
    required this.content,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sections.isNotEmpty)
              ...sections.map((sec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sec['content'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
                      ),
                      if (sec['items'] != null && sec['items'] is List)
                        ...List<Widget>.from(
                          (sec['items'] as List).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                                  Expanded(
                                    child: Text(
                                      item.toString(),
                                      style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList()
            else
              Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
              ),
          ],
        ),
      ),
    );
  }
}
