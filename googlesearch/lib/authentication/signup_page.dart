import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/web/web_screen_layout.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _otpController = TextEditingController();

  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'BD');
  String _phoneCompleteNumber = '';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneSignup = false;
  bool _isOtpSent = false;
  String _enteredPhoneForOtp = '';

  void _onPhoneNumberChanged(PhoneNumber number) {
    _phoneCompleteNumber = number.phoneNumber ?? '';
  }
  

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final fullName = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final gender = _genderController.text.trim();
     final password = _passwordController.text;


    setState(() => _isLoading = true);

    try {
      if (_isPhoneSignup) {
        if (_phoneCompleteNumber.isEmpty) {
          _showSnack('Please enter your phone number');
          setState(() => _isLoading = false);
          return;
        }

        await supabase.auth.signInWithOtp(
          phone: _phoneCompleteNumber,
          
        );

print('Sending OTP to phone number: $_phoneCompleteNumber');

        _showSnack('OTP sent to $_phoneCompleteNumber');
        setState(() {
          _isOtpSent = true;
          _enteredPhoneForOtp = _phoneCompleteNumber;
        });
      } else {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user == null) throw Exception('User not found after signup');

        await supabase.from('profiles').insert({
          'user_id': user.id,
          'full_name': fullName,
          'age': age,
          'gender': gender,
        });

        if (mounted) {
        //  Navigator.pushReplacementNamed(context, '/webscreenlayout');
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const WebScreenLayout()),
);

        }
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Error during signup: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _verifyOtp() async {
    final supabase = Supabase.instance.client;
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack('Please enter the OTP code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        phone: _enteredPhoneForOtp,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw Exception('OTP verification failed');
      }

     Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const WebScreenLayout()),
);

    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isOtpSent ? "Verify OTP" : "Sign Up",
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: 600,
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.shade100, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              offset: const Offset(3, 3),
              blurRadius: 5,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-3, -3),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Lottie animation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Lottie.asset(
                    'assets/animations/welcome2.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Right: Either OTP input or full form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _isOtpSent ? _buildOtpInputSection() : _buildSignupFormSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter the OTP sent to',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _enteredPhoneForOtp,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'OTP Code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 6,
            shadowColor: Colors.blueGrey.withOpacity(0.4),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Verify OTP',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSignupFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Email'),
                selected: !_isPhoneSignup,
                onSelected: (selected) => setState(() => _isPhoneSignup = !selected),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Phone'),
                selected: _isPhoneSignup,
                onSelected: (selected) => setState(() => _isPhoneSignup = selected),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isPhoneSignup) ...[
            _buildTextField(_emailController, "Email", Icons.email, validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!EmailValidator.validate(value.trim())) return 'Enter a valid email';
              return null;
            }),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, "Password", Icons.lock,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a password';
                  if (value.length < 6) return 'Min 6 characters';
                  return null;
                }),
          ] else ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: InternationalPhoneNumberInput(
                onInputChanged: _onPhoneNumberChanged,
                initialValue: _phoneNumber,
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DROPDOWN,
                ),
                inputDecoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                formatInput: true,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your phone';
                  return null;
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildTextField(_nameController, "Full Name", Icons.person),
          const SizedBox(height: 16),
          _buildTextField(_ageController, "Age", Icons.calendar_today,
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTextField(_genderController, "Gender", Icons.transgender),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 6,
              shadowColor: Colors.blueGrey.withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Sign Up",
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              "Already have an account? Login",
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B4B42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, Widget? suffixIcon, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        validator: validator,
      ),
    );
  }
}
