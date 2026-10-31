import 'hotel_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/models/owner_profile_model.dart';
import '../core/models/user_model.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/yaan_ui.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

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

  // Google Play requires apps with sign-up to offer account deletion
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, KYC documents and bank details, '
          'and remove your hotel from Yaan. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFC0392B))),
    );

    String? errorMsg;
    try {
      final token = await ApiService.getToken();
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/account'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 60));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body is Map && body['success'] == true) {
        await ApiService.clearToken();
        await _authService.logout();
      } else {
        errorMsg = (body is Map ? (body['message'] ?? body['error']) : null)?.toString() ?? 'Could not delete account.';
      }
    } catch (e) {
      errorMsg = 'Could not delete account. Please check your internet and try again.';
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loading

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  Future<void> _openEditProfile() async {
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
  }

  String get _displayName {
    if (_profile != null && _profile!.ownerName.isNotEmpty) return _profile!.ownerName;
    if (_user != null && _user!.name.isNotEmpty) return _user!.name;
    return 'User Name';
  }

  @override
  Widget build(BuildContext context) {
    final bool isApproved = (_kycStatus == 'approved' || _kycStatus == 'active') &&
        (_hotelStatus == 'approved' || _hotelStatus == 'active');

    return Scaffold(
      backgroundColor: YaanColors.ground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: YaanColors.brand))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildKycNotificationCard(),
                        if (isApproved) ...[
                          _buildQrCard(),
                          const SizedBox(height: 14),
                        ],
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: YaanSectionTitle('Other information'),
                        ),
                        YaanCard(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children: [
                              _buildListTile(Icons.image_outlined, 'Add Image', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Add Image feature selected.')),
                                );
                              }),
                              _buildListTile(Icons.photo_library_outlined, 'View Gallery', () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('View Gallery feature selected.')),
                                );
                              }),
                              _buildListTile(Icons.description_outlined, 'Terms & Conditions', () {
                                _openLegalPage('/vendor/terms-and-conditions', 'Terms & Conditions');
                              }),
                              _buildListTile(Icons.info_outline, 'About Us', () {
                                _openLegalPage('/vendor/about', 'About Us');
                              }),
                              _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                                _openLegalPage('/vendor/privacy-policy', 'Privacy Policy');
                              }),
                              _buildListTile(Icons.headset_mic_outlined, 'Contact Us', () {
                                _openLegalPage('/vendor/contact', 'Contact Us');
                              }),
                              _buildListTile(Icons.share_outlined, 'Share App', () {
                                _openLegalPage('/vendor/share', 'Share App');
                              }),
                              _buildListTile(Icons.star_outline_rounded, 'Rate Us', () {
                                _openLegalPage('/vendor/rate', 'Rate Us');
                              }),
                              _buildListTile(Icons.help_outline, 'FAQ', () {
                                _openLegalPage('/vendor/faq', 'Frequently Asked Questions');
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        YaanPrimaryButton(
                          text: 'Log out',
                          icon: Icons.logout_rounded,
                          color: YaanColors.navy,
                          height: 52,
                          onPressed: _logout,
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever_outlined, color: YaanColors.red, size: 18),
                          label: const Text(
                            'Delete Account',
                            style: TextStyle(color: YaanColors.red, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
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

    final Color bgColor = isRejected ? YaanColors.redTint : (isPending ? YaanColors.amberTint : YaanColors.greenTint);
    final Color borderColor = isRejected
        ? const Color(0xFFF8C9C4)
        : (isPending ? const Color(0xFFF6DDAE) : const Color(0xFFBFE5CD));
    final Color iconColor = isRejected ? YaanColors.red : (isPending ? YaanColors.amber : YaanColors.green);
    final Color textColor = isRejected ? const Color(0xFF7A1B12) : (isPending ? YaanColors.amberText : YaanColors.greenText);

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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRejected
                ? Icons.error_outline_rounded
                : (isPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded),
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 2),
                Text(bodyMessage, style: TextStyle(fontSize: 12, height: 1.45, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: const BoxDecoration(
        color: YaanColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: YaanColors.brand, shape: BoxShape.circle),
                    child: Text(
                      yaanInitials(_displayName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
                        ),
                        Text(
                          _user?.email ?? 'user@email.com',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: YaanColors.headerSub, fontSize: 12),
                        ),
                        Text(
                          _user?.phone ?? '99999 99999',
                          style: const TextStyle(color: YaanColors.headerSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _openEditProfile,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.edit_outlined, color: Colors.white, size: 20, semanticLabel: 'Edit profile'),
                      ),
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

  Widget _buildQrCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelQrScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3D3CF)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: YaanColors.brand, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hotel QR Standee & Share', style: TextStyle(color: YaanColors.ink, fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Print your QR so drivers can spot book', style: TextStyle(color: YaanColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: YaanColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: YaanColors.ground, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: YaanColors.ink, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: YaanColors.ink, fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: YaanColors.muted, size: 20),
          ],
        ),
      ),
    );
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
      backgroundColor: YaanColors.ground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: YaanColors.ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
        title: Text(title, style: const TextStyle(color: YaanColors.ink, fontWeight: FontWeight.w600, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: YaanCard(
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YaanColors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sec['content'] ?? '',
                          style: const TextStyle(fontSize: 14, height: 1.5, color: YaanColors.body),
                        ),
                        if (sec['items'] != null && sec['items'] is List)
                          ...List<Widget>.from(
                            (sec['items'] as List).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: YaanColors.brand)),
                                    Expanded(
                                      child: Text(
                                        item.toString(),
                                        style: const TextStyle(fontSize: 14, height: 1.4, color: YaanColors.body),
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
                })
              else
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: YaanColors.body),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
