import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Executive Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 68, 24, 36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFC0392B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC0392B).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Partner Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in your details to start listing your hotel properties',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Owner Full Name',
                            hintText: 'Jane Doe',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFFC0392B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Work Email Address',
                            hintText: 'owner@hotel.com',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFFC0392B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            hintText: '9876543210',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFFC0392B),
                            ),
                            prefixText: '+91  ',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Register & Send OTP',
                    onPressed: _submit,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already registered?',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFFC0392B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
