// ignore_for_file: use_super_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchResultComponent extends StatefulWidget {
  final String linkToGo;
  final String link;
  final String text;
  final String desc;
  final String? imageUrl;
  final String? ageCategory;

  const SearchResultComponent({
    Key? key,
    required this.linkToGo,
    required this.link,
    required this.text,
    required this.desc,
    this.imageUrl,
    this.ageCategory
  }) : super(key: key);

  @override
  State<SearchResultComponent> createState() => _SearchResultComponentState();
}

class _SearchResultComponentState extends State<SearchResultComponent> {
  bool isBookmarked = false;
  late Box box;

  @override
  void initState() {
    super.initState();
    _initBookmarkStatus();
  }

  Future<void> _initBookmarkStatus() async {
    box = await Hive.openBox('bookmarks');
    final existing = box.values.firstWhere(
      (element) => element is Map && element['linkToGo'] == widget.linkToGo,
      orElse: () => null,
    );
     if (!mounted) return; // Prevent setState after dispose
    setState(() {
      isBookmarked = existing != null;
    });
  }
Future<void> _toggleBookmark() async {
  final existingKey = box.keys.firstWhere(
    (key) => box.get(key)?['linkToGo'] == widget.linkToGo,
    orElse: () => null,
  );

  if (existingKey != null) {
    await box.delete(existingKey);
    if (!mounted) return; //  Safe check
    setState(() => isBookmarked = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from bookmarks")),
    );
  } else {
   await box.add({
  'type': 'normal',
  'linkToGo': widget.linkToGo,
  'link': widget.link,
  'text': widget.text,
  'desc': widget.desc,
  'imageUrl': widget.imageUrl,
  'ageCategory': widget.ageCategory?.toLowerCase(), // add this line
  'timestamp': DateTime.now().toIso8601String(),
});

    if (!mounted) return; //  Safe check
    setState(() => isBookmarked = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bookmarked!")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.link,
                        style: textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(widget.linkToGo);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Text(
                          widget.text,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.desc,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⭐ Bookmark Icon
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.orange : Colors.grey,
              ),
              tooltip: isBookmarked ? 'Remove Bookmark' : 'Add to Bookmarks',
              onPressed: _toggleBookmark,
            ),
          ),
        ],
      ),
    );
  }
}
