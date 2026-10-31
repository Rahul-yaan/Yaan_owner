import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/yaan_ui.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final int userId;
  final String phoneNumber;

  const OtpScreen({super.key, required this.userId, required this.phoneNumber});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _passVisible = false;

  Future<void> _verify() async {
    final otp = _otpCtrl.text;
    if (otp.length != 6) {
      _snack('Enter complete 6-digit OTP');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _snack('Password min 6 characters');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    final idToken = await _authService.verifyOtp(otp);
    if (idToken == null) {
      setState(() => _loading = false);
      _snack('Wrong OTP. Try again.');
      return;
    }

    final result = await ApiService.verifyOtp(
      userId: widget.userId,
      firebaseIdToken: idToken,
      password: _passCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );

    setState(() => _loading = false);

    // Error replies also contain 'message', so check success + token
    if (result['success'] == true && result['token'] != null) {
      _snack('Verified! Please login.');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
      }
    } else {
      _snack((result['message'] ?? result['error'] ?? 'Verification failed').toString());
    }
  }

  Future<void> _resendOtp() async {
    _snack('Resending OTP...');
    await _authService.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: () => _snack('OTP Resent!'),
      onError: (err) => _snack(err),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: YaanColors.ink,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: YaanColors.field,
        border: Border.all(color: YaanColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      color: Colors.white,
      border: Border.all(color: YaanColors.brand, width: 2),
      borderRadius: BorderRadius.circular(14),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const YaanBackButton(),
                    const SizedBox(height: 16),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: YaanColors.brandTint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.phone_iphone_rounded, color: YaanColors.brand, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Owner Verification',
                      style: TextStyle(color: YaanColors.ink, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: YaanColors.muted, fontSize: 14, height: 1.5, fontFamily: 'Poppins'),
                        children: [
                          const TextSpan(text: 'Enter the 6-digit code sent to '),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(color: YaanColors.ink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const YaanFieldLabel('Verification code'),
                    Pinput(
                      length: 6,
                      controller: _otpCtrl,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      autofocus: true,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text("Didn't get it?", style: TextStyle(color: YaanColors.muted, fontSize: 12)),
                        TextButton(
                          onPressed: _resendOtp,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(color: YaanColors.brand, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                    const SizedBox(height: 20),
                    const Text(
                      'Set your password',
                      style: TextStyle(color: YaanColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const YaanFieldLabel('Password'),
                    TextField(
                      controller: _passCtrl,
                      obscureText: !_passVisible,
                      decoration: yaanInputDecoration(
                        hint: 'Enter at least 6 characters',
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
                    const SizedBox(height: 6),
                    const Text('At least 6 characters', style: TextStyle(color: YaanColors.muted, fontSize: 11)),
                    const SizedBox(height: 14),
                    const YaanFieldLabel('Confirm password'),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: yaanInputDecoration(hint: 'Re-enter your password', icon: Icons.lock_reset_rounded),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: YaanPrimaryButton(
                text: 'Verify & Continue',
                onPressed: _verify,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
