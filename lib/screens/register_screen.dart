import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/yaan_ui.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _snack('All fields are required');
      return;
    }
    if (phone.length != 10) {
      _snack('Enter valid 10-digit phone number');
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.register(
      name: name,
      email: email,
      phone: '+91$phone',
    );

    print("========== REGISTER RESPONSE ==========");
    print(result);
    print("======================================");

    if (result['error'] != null || result['errors'] != null) {
      setState(() => _loading = false);
      final errorMsg =
          result['error'] ?? result['message'] ?? 'Registration failed';
      _snack(errorMsg);
      return;
    }

    if (result['user_id'] == null) {
      setState(() => _loading = false);
      _snack('Registration failed. Please try again.');
      return;
    }

    final userId = result['user_id'] as int;

    await _authService.sendOtp(
      phoneNumber: '+91$phone',
      onCodeSent: () {
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(userId: userId, phoneNumber: '+91$phone'),
          ),
        );
      },
      onError: (err) {
        setState(() => _loading = false);
        _snack(err);
      },
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _goToLogin() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaanColors.ground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navy header with the 3 steps to go live
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 64),
              decoration: const BoxDecoration(
                color: YaanColors.navy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YaanBackButton(onDark: true, onTap: _goToLogin),
                  const SizedBox(height: 18),
                  const Text(
                    'BECOME A YAAN PARTNER',
                    style: TextStyle(
                      color: YaanColors.headerKicker,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Register Partner Account',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in your details to start listing your hotel',
                    style: TextStyle(color: YaanColors.headerSub, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _stepDot('1', 'Account', active: true),
                      _stepLine(),
                      _stepDot('2', 'Hotel details'),
                      _stepLine(),
                      _stepDot('3', 'Approval'),
                    ],
                  ),
                ],
              ),
            ),

            // Form card overlapping the header
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: YaanColors.ink.withValues(alpha: 0.10),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const YaanFieldLabel('Owner full name'),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: yaanInputDecoration(hint: 'Jane Doe', icon: Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 16),
                      const YaanFieldLabel('Work email address'),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: yaanInputDecoration(hint: 'owner@hotel.com', icon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      const YaanFieldLabel('Mobile number'),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: yaanInputDecoration(hint: '9876543210', icon: Icons.phone_outlined, prefixText: '+91  '),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'We will send a 6-digit OTP to this number',
                        style: TextStyle(color: YaanColors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      YaanPrimaryButton(
                        text: 'Register & Send OTP',
                        onPressed: _submit,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already registered?', style: TextStyle(color: YaanColors.muted, fontSize: 13)),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(color: YaanColors.brand, fontWeight: FontWeight.w600),
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

  Widget _stepDot(String number, String label, {bool active = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? YaanColors.brand : Colors.transparent,
            shape: BoxShape.circle,
            border: active ? null : Border.all(color: const Color(0xFF5C6878)),
          ),
          child: Text(
            number,
            style: TextStyle(color: active ? Colors.white : YaanColors.headerSub, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : YaanColors.headerSub,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _stepLine() => Expanded(
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.white.withValues(alpha: 0.25),
        ),
      );
}
