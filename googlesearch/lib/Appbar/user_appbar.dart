// widgets/user_app_bar.dart
// ignore_for_file: prefer_const_constructors, use_super_parameters, unused_element, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:googlesearch/BooksMark/book_marks.dart';
import 'package:googlesearch/BooksMark/entry_bookmarks.dart';

import 'package:googlesearch/History/entry_history.dart';
import 'package:googlesearch/History/history_page.dart';
import 'package:googlesearch/Profile/edit_profile.dart';
import 'package:googlesearch/Screens/search_screen.dart';
import 'package:googlesearch/main.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAppBar extends StatefulWidget implements PreferredSizeWidget {
  const UserAppBar({Key? key}) : super(key: key);

  @override
  State<UserAppBar> createState() => _UserAppBarState();

  // 🔁 Returns the height of the custom app bar (standard toolbar height)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _UserAppBarState extends State<UserAppBar> {
  /// 🟢 Extracts and capitalizes the first name from a full name string.
  /// Returns 'User' if the name is null or empty.
  String _getUserFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'User';
    final parts = fullName.trim().split(' ');
    return parts.first[0].toUpperCase() + parts.first.substring(1);
  }

  /// 🔍 Opens a dialog showing the search history for the current user.
  /// Returns void, but shows a list and navigates to the search screen on tap.
  void _showHistory(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final box = await Hive.openBox('history_${user.id}');
    final history = box.values.toList().reversed.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search History'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: history.isEmpty
              ? const Center(child: Text("No history yett."))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final query = item['query'] ?? '';
                    final ageCategory = item['ageCategory'] ?? 'unknown';
                    final timestamp = item['timestamp'] != null
                        ? DateTime.tryParse(item['timestamp'])?.toLocal()
                        : null;

                    final formattedTime = timestamp != null
                        ? "${timestamp.day}/${timestamp.month}/${timestamp.year}  ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}"
                        : 'Unknown time';

                    return ListTile(
                      title: Text(query),
                      subtitle: Text('Searched on: $formattedTime'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchScreen(
                              searchQuery: query,
                              ageCategory: ageCategory,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// 📚 Opens a dialog showing the bookmarks for the current user.
  /// Returns void, but shows list and navigates to search screen on tap.
  void _showBookmarks(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final box = await Hive.openBox('bookmarks_${user.id}');
    final bookmarks = box.values.toList().reversed.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bookmarks'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: bookmarks.isEmpty
              ? const Center(child: Text("No bookmarks yet."))
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final item = bookmarks[index];
                      final ageCategory = item['ageCategory'] ?? 'unknown';
                    
                    final bookmark = bookmarks[index];
                    final time = DateTime.parse(bookmark['timestamp']);
                    return ListTile(
                      title: Text(bookmark['title']),
                      subtitle: Text(
                          "${bookmark['description']}\n${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchScreen(
                              searchQuery: bookmark['title'],
                              ageCategory: ageCategory,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  ///  Builds the custom AppBar widget based on user login and theme.
  /// Returns an AppBar widget with profile, history, bookmark, and theme toggle buttons.
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.of(context);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return AppBar(title: Text("Welcome 👋"));

    return FutureBuilder(
      future: Supabase.instance.client
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('user_id', user.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = _getUserFirstName(data?['full_name']);
        final imageUrl = data?['profile_image_url'];

        return AppBar(
          title: Text("Welcome $name 👋"),
          actions: [
            // 🟢 Profile icon or image
            IconButton(
              tooltip: 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              },
              icon: imageUrl != null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(imageUrl),
                      backgroundColor: Colors.transparent,
                    )
                  : const Icon(Icons.person),
            ),

            // 🔍 Search history button
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Search History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntryHistory()),
                );
              },
            ),

            // 📌 Bookmarks button
            IconButton(
              icon: const Icon(Icons.bookmark),
              tooltip: 'Bookmarks',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntryBookmarks()),
                );
              },
            ),

            // 🌗 Theme switch (light/dark)
            Row(
              children: [
                const Icon(Icons.light_mode),
                Switch(
                  value: themeController.isDark,
                  onChanged: themeController.toggleTheme,
                ),
                const Icon(Icons.dark_mode),
                const SizedBox(width: 12),
              ],
            )
          ],
        );
      },
    );
  }
}
