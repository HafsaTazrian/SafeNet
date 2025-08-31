import 'package:flutter/material.dart';
import 'package:googlesearch/web/web_screen_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOTPSent = false;
  String _phoneNumber = '';

  Future<void> sendOTP() async {
    final fullPhone = '+880${_phoneController.text.trim()}';
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: fullPhone,
      );
      setState(() {
        _isOTPSent = true;
        _phoneNumber = fullPhone;
      });
    } catch (e) {
      print('Error sending OTP: $e');
    }
  }

  Future<void> verifyOTP() async {
    final otp = _otpController.text.trim();
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: _phoneNumber,
      );

      if (response.user != null) {
        // Redirect to WebScreenLayout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WebScreenLayout()),
        );
      } else {
        print('OTP verification failed.');
      }
    } catch (e) {
      print('OTP error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Auth")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isOTPSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number (e.g. 1611173166)",
                ),
              ),
            if (_isOTPSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isOTPSent ? verifyOTP : sendOTP,
              child: Text(_isOTPSent ? 'Verify OTP' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}