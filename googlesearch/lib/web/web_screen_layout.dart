// ignore_for_file: unused_local_variable, prefer_const_constructors, use_super_parameters

import 'package:flutter/material.dart';
import 'package:googlesearch/Appbar/user_appbar.dart';
import 'package:googlesearch/Favourite/favourite_section.dart';
import 'package:lottie/lottie.dart';
import 'package:googlesearch/widgets/search.dart';
import '../main.dart'; // import ThemeController

class WebScreenLayout extends StatelessWidget {
  const WebScreenLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeController = ThemeController.of(context);  // Access the current theme controller

    return SafeArea(
      child: Scaffold(
        appBar: UserAppBar(),  // Custom app bar widget for the user
        body: Stack(
          children: [
            // Background animation filling entire screen
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Lottie.asset(
                    'assets/animation.json',
                    fit: BoxFit.cover,
                    repeat: true,
                  ),
                ),
              ),
            ),

            // Foreground content with some padding
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.25), // Space from top before main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: const [
                          SizedBox(height: 40),
                          Search(),             // Search widget for user queries
                          SizedBox(height: 20),
                          FavouritesSection()    // Shows user's favourite items or searches
                        ],
                      ),
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
}
