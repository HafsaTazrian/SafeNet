import 'package:flutter/material.dart';
import 'package:googlesearch/widgets/search_result_component.dart';
import 'package:googlesearch/utils/safe_search_result.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // for formatting timestamp

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<dynamic> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks(); // Load bookmarks when the screen initializes
  }

  // Function to load bookmarks from Hive storage
 Future <void> _loadBookmarks() async {
  final box = await Hive.openBox('bookmarks');
  final all = box.values.toList();
  for (var item in all) {
    print('ageCategory: ${item['ageCategory']}');
  }
  setState(() {
    _bookmarks = all.reversed.toList();
  });
}


  // Function to delete a specific bookmark based on index
  Future<void> _deleteBookmark(int index) async {
    final box = await Hive.openBox('bookmarks');
    final key = box.keyAt(box.length - 1 - index); // Adjust index since list is reversed
    await box.delete(key); // Delete the bookmark using its key
    _loadBookmarks(); // Reload bookmarks after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmarks"), // App bar title
      ),
      body: _bookmarks.isEmpty
          ? const Center(child: Text("No bookmarks yet.")) // Show message if list is empty
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final item = _bookmarks[index];

                // Format timestamp if present
                String formattedTime = "";
                if (item['timestamp'] != null) {
                  final dateTime = DateTime.tryParse(item['timestamp']);
                  if (dateTime != null) {
                    formattedTime = DateFormat('yyyy-MM-dd hh:mm a').format(dateTime); // Format time nicely
                  }
                }

                Widget card;

                // Render SafeSearchResultCard if type is 'safe'
                if (item['type'] == 'safe') {
                  card = SafeSearchResultCard(
  title: item['title'],
  description: item['description'],
  imageUrl: item['image'],
  resources: (item['resources'] as List)
    .map((res) => Map<String, String>.from(res as Map))
    .toList(),
  ageCategory: item['ageCategory'], // 👈 Add this line
);
                }
                // Otherwise render regular SearchResultComponent
                else {
                  card = SearchResultComponent(
                    linkToGo: item['linkToGo'],
                    link: item['link'],
                    text: item['text'],
                    desc: item['desc'],
                    imageUrl: item['imageUrl'],
                    ageCategory: item['ageCategory'],
                   
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    card, // Display the bookmark card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (formattedTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text(
                              "Saved on: $formattedTime", // Show formatted timestamp
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        // Delete icon with confirmation dialog
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            // Show confirmation dialog before deleting
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Bookmark?'),
                                content: const Text('Are you sure you want to remove this bookmark?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              _deleteBookmark(index); // Proceed with deletion
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(), // Separator line between bookmarks
                  ],
                );
              },
            ),
    );
  }
}
