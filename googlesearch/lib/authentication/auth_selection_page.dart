import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/authentication/login_page.dart';
import 'package:googlesearch/authentication/signup_page.dart';
import 'package:lottie/lottie.dart';

/// Page that allows user to choose between Sign Up and Login
class AuthSelectionPage extends StatelessWidget {
  const AuthSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 600,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
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
              // Left side: Animated welcome illustration
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
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
                    'assets/animations/welcome1.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Right side: Title, description text, and buttons for Sign Up and Login
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated welcome text
                      SizedBox(
                        height: 60,
                        child: DefaultTextStyle(
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 38,
                            color: const Color(0xFF7B4B42),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Welcome to Safenet',
                                speed: Duration(milliseconds: 100),
                                cursor: "|",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description about the app's safety and purpose
                      Text(
                        '''Explore the internet with confidence, designed especially for kids and families.
Enjoy a fun, secure, and educational browsing experience every time.
No harmful content, no distractions — just safe and smart searching.
Your digital safety is our top priority.''',
                        style: GoogleFonts.dancingScript(
                          fontSize: 26,
                          height: 1.6,
                          color: Colors.blueGrey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Row with Sign Up and Login buttons
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Navigates to SignUpPage (no parameters passed)
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 6,
                              shadowColor: Colors.blueGrey.withOpacity(0.4),
                            ),
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Navigates to LogInPage (no parameters passed)
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 6,
                              shadowColor: Colors.blueGrey.withOpacity(0.4),
                            ),
                            child: Text(
                              "Login",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
