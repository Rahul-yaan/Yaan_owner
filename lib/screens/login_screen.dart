import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/yaan_ui.dart';
import 'hotel_setup_screen.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _passVisible = false;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Enter email and password');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    setState(() => _loading = false);

    if (result['token'] != null) {
      await ApiService.saveToken(result['token']);
      
      // Check if owner already has a hotel setup
      final hotelsRes = await ApiService.getOwnerHotels();
      
      if (mounted) {
        if (hotelsRes['hotels'] != null && (hotelsRes['hotels'] as List).isNotEmpty) {
          // Has hotel, go to dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (r) => false,
          );
        } else {
          // No hotel, go to setup screen (owner profile page)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HotelSetupScreen()),
            (r) => false,
          );
        }
      }
    } else {
      _snack(result['error'] ?? 'Login failed');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaanColors.ground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navy header
            Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 32, 24, 72),
              decoration: const BoxDecoration(
                color: YaanColors.navy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: YaanColors.brand, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'YAAN PARTNER PORTAL',
                    style: TextStyle(color: YaanColors.headerKicker, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Owner Login',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your properties, bookings, and revenue',
                    style: TextStyle(color: YaanColors.headerSub, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Login card overlapping the header
            Transform.translate(
              offset: const Offset(0, -44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: YaanColors.ink.withValues(alpha: 0.10), blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const YaanFieldLabel('Email address'),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: yaanInputDecoration(hint: 'owner@domain.com', icon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      const YaanFieldLabel('Password'),
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_passVisible,
                        decoration: yaanInputDecoration(
                          hint: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            tooltip: _passVisible ? 'Hide password' : 'Show password',
                            icon: Icon(
                              _passVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: YaanColors.muted,
                            ),
                            onPressed: () => setState(() => _passVisible = !_passVisible),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: YaanColors.brand, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      YaanPrimaryButton(
                        text: 'Sign In to Portal',
                        onPressed: _login,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Expanded(child: Divider(color: YaanColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('New to Yaan?', style: TextStyle(color: YaanColors.muted, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: YaanColors.border)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    YaanOutlineButton(
                      text: 'Register Partner',
                      color: YaanColors.brand,
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'List your highway hotel or dhaba and get bookings from truck drivers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: YaanColors.muted, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
