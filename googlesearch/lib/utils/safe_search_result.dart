import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/chatbot/chat_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

/// A card widget that displays safe search result content
/// including title, description, image, resources links,
/// and an interactive chatbot section.
/// Also supports bookmarking functionality.
class SafeSearchResultCard extends StatefulWidget {
  final String title;
  final String description; 
  final String imageUrl; 
  final List<Map<String, String>> resources;
   final String? ageCategory;

  final String? matchedKeyword; 

  const SafeSearchResultCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.resources,
    this.matchedKeyword,
    this.ageCategory
  });

  @override
  State<SafeSearchResultCard> createState() => _SafeSearchResultCardState();
}

class _SafeSearchResultCardState extends State<SafeSearchResultCard> {
  bool isBookmarked = false; 
  late Box box; // Hive box for bookmarks storage

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus(); // Check if this content is already bookmarked on widget load
  }

  /// Opens the Hive box and checks if the current content
  /// is already saved/bookmarked
  Future<void> _checkBookmarkStatus() async {
    box = await Hive.openBox('bookmarks');
    final existing = box.values.firstWhere(
      (element) =>
          element is Map &&
          element['type'] == 'safe' &&
          element['title'] == widget.title &&
          element['description'] == widget.description,
      orElse: () => null,
    );
    if (mounted) {
      setState(() {
        isBookmarked = existing != null;
      });
    }
  }

  /// Toggles the bookmark status of this content:
  /// If already bookmarked, removes it.
  /// Otherwise, adds it to bookmarks.
  Future<void> _toggleBookmark() async {
    final existingKey = box.keys.firstWhere(
      (key) {
        final item = box.get(key);
        return item is Map &&
            item['type'] == 'safe' &&
            item['title'] == widget.title &&
            item['description'] == widget.description;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      // Remove bookmark
      await box.delete(existingKey);
      setState(() => isBookmarked = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from bookmarks")),
      );
    } else {
      // Add bookmark only if user is logged in
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await box.add({
          'type': 'safe',
          'title': widget.title,
          'description': widget.description,
          'image': widget.imageUrl,
          'resources':
              widget.resources.map((r) => Map<String, String>.from(r)).toList(),
          'timestamp': DateTime.now().toIso8601String(),
          'ageCategory': widget.ageCategory?.toLowerCase(),
        });

        setState(() => isBookmarked = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bookmarked!")),
        );
      }
    }
  }

  /// Helper function to launch external URLs safely in browser
  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Stack(
          children: [
            Card(
              elevation: 8,
              color: theme.cardColor,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left half: image, title, description, resources
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rounded image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.imageUrl,
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title with PlayfairDisplay font, bold
                              Text(
                                widget.title,
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.textTheme.titleLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Description text
                              Text(
                                widget.description,
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Helpful Resources section if any
                              if (widget.resources.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Helpful Resources:",
                                      style: GoogleFonts.playfairDisplay(
                                        color: theme.textTheme.titleLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Wrap buttons for resources
                                    Wrap(
                                      spacing: 9,
                                      runSpacing: 12,
                                      children: widget.resources
                                          .map((res) {
                                            final label = res['label'];
                                            final url = res['url'];
                                            if (label != null && url != null) {
                                              return _buildLinkButton(
                                                  context, label, url);
                                            }
                                            return const SizedBox.shrink();
                                          })
                                          .toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24), // Space between columns

                        // Right half: Lottie chatbot animation + explanation + chat button
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Chatbot Lottie animation
                                SizedBox(
                                  height: 180,
                                  child: Lottie.asset('assets/animations/chatbot.json'),
                                ),
                                const SizedBox(height: 16),

                                // Explanation text about safe content and chatbot
                                Text(
                                  '🧠 Curious About ${widget.matchedKeyword?.toUpperCase() ?? "This Topic"}?\n\n'
                                  'This is a serious topic, and we’re here to help you understand it safely and simply.\n\n'
                                  'You’re not alone in asking about this — many kids have questions too.\n\n'
                                  'We’ll explain things in a way that’s clear, honest, and right for your age.\n\n'
                                  'It’s okay to be curious — learning the truth can help you make smart choices.',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    color: Colors.blueGrey[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 24),

                                // Button to open chatbot screen
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ChatScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 16),
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Chat with me',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Positioned Bookmark Icon at top-right corner of card
            Positioned(
              top: 16,
              right: 20,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.orange : Colors.grey,
                ),
                tooltip: isBookmarked
                    ? 'Remove Bookmark'
                    : 'Bookmark this content',
                onPressed: _toggleBookmark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled button for external resource links
  Widget _buildLinkButton(BuildContext context, String text, String url) {
    final theme = Theme.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: theme.colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _launchURL(url),
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(color: Colors.white),
      ),
    );
  }
}
