import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/authentication/login_success.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'BD');
  String _phoneCompleteNumber = '';
  bool _isPhoneLogin = false;

  bool _isLoading = false;

  void _onPhoneNumberChanged(PhoneNumber number) {
    _phoneCompleteNumber = number.phoneNumber ?? '';
  }

  Future<void> _login() async {
    final supabase = Supabase.instance.client;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isPhoneLogin) {
      if (_phoneCompleteNumber.isEmpty) {
        _showSnack('Please enter your phone number');
        return;
      }
    } else {
      if (email.isEmpty) {
        _showSnack('Please enter your email');
        return;
      }
      if (!email.contains('@')) {
        _showSnack('Please enter a valid email');
        return;
      }
    }

    if (password.isEmpty) {
      _showSnack('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _isPhoneLogin ? null : email,
        phone: _isPhoneLogin ? _phoneCompleteNumber : null,
        password: password,
      );

      if (response.user == null) throw Exception('Login failed');

      // Navigate to your existing LoginSuccess page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginSuccess()),
        );
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Login",
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: 600,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        padding: const EdgeInsets.all(24),
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
            // Left side: Lottie animation
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Lottie.asset(
                  'assets/animations/login.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Right side: Login form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Toggle email / phone login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Email'),
                          selected: !_isPhoneLogin,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isPhoneLogin = false);
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Phone'),
                          selected: _isPhoneLogin,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isPhoneLogin = true);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Email or Phone input
                    if (!_isPhoneLogin)
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      )
                    else
                      InternationalPhoneNumberInput(
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
                      ),

                    const SizedBox(height: 16),

                    // Password input
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      obscureText: true,
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 32),
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
                              "Login",
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
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
