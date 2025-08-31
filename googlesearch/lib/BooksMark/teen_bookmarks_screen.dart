import 'package:flutter/material.dart';
import 'package:googlesearch/widgets/search_result_component.dart';
import 'package:googlesearch/utils/safe_search_result.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class TeenBookmarksScreen extends StatefulWidget {
  const TeenBookmarksScreen({super.key});

  @override
  State<TeenBookmarksScreen> createState() => _TeenBookmarksScreenState();
}
class _TeenBookmarksScreenState extends State<TeenBookmarksScreen> {
  List<MapEntry<dynamic, dynamic>> _filteredBookmarksWithKeys = [];

  @override
  void initState() {
    super.initState();
    _loadFilteredBookmarks();
  }

  Future<void> _loadFilteredBookmarks() async {
    final box = await Hive.openBox('bookmarks');
    final entries = box.toMap().entries.toList().reversed.toList();

    _filteredBookmarksWithKeys = entries.where((entry) {
      final item = entry.value;
      if (item is! Map || item['ageCategory'] == null) return false;
      final ageCat = item['ageCategory'].toString().toLowerCase();
      return ageCat == 'fifties' || ageCat == 'twenties';
    }).toList();

    setState(() {});
  }

  Future<void> _deleteBookmark(int index) async {
    final box = await Hive.openBox('bookmarks');
    if (index < _filteredBookmarksWithKeys.length) {
      final key = _filteredBookmarksWithKeys[index].key;
      await box.delete(key);
      await _loadFilteredBookmarks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teen Bookmarks")),
      body: _filteredBookmarksWithKeys.isEmpty
          ? const Center(child: Text("No bookmarks found for this age group."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredBookmarksWithKeys.length,
              itemBuilder: (context, index) {
                final item = _filteredBookmarksWithKeys[index].value;

                // Format timestamp
                String formattedTime = "";
                if (item['timestamp'] != null) {
                  final dateTime = DateTime.tryParse(item['timestamp']);
                  if (dateTime != null) {
                    formattedTime =
                        DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
                  }
                }

                Widget card;
                if (item['type'] == 'safe') {
                  card = SafeSearchResultCard(
                    title: item['title'],
                    description: item['description'],
                    imageUrl: item['image'],
                     ageCategory: item['ageCategory'], 
                    resources:
                        (item['resources'] as List)
    .map((res) => Map<String, String>.from(res as Map))
    .toList(),



                  );
                  print("Rendering SafeSearchResultCard with title: ${item['title']}");

                } else {
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
                    card,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (formattedTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text(
                              "Saved on: $formattedTime",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Bookmark?'),
                                content: const Text(
                                    'Are you sure you want to remove this bookmark?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              _deleteBookmark(index);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}
