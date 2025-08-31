import 'package:flutter/material.dart';
import 'package:googlesearch/History/entry_history.dart';
import 'package:googlesearch/authentication/auth_selection_page.dart';
import 'package:googlesearch/web/web_screen_layout.dart';
import 'package:googlesearch/widgets/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Decides which screen to show based on user authentication state
class ToggleSwitchPage extends StatelessWidget {
  const ToggleSwitchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser; // Current authenticated user

    return Scaffold(
      // If user is logged in, show the main web screen layout
      // Otherwise, show the authentication selection page (login/signup)
      body: user != null
          ? WebScreenLayout()
          : const AuthSelectionPage(),
    );
  }
}
