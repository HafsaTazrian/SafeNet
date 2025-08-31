// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class FavouritesSection extends StatefulWidget {
  const FavouritesSection({super.key});

  @override
  State<FavouritesSection> createState() => _FavouritesSectionState();
}

class _FavouritesSectionState extends State<FavouritesSection> {
  late Box favouritesBox;

  @override
  void initState() {
    super.initState();
    favouritesBox = Hive.box('favourites');
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Favourite'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                favouritesBox.add({'name': name, 'url': url});
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  void _showEditDialog(int index, String currentName, String currentUrl) {
  final nameController = TextEditingController(text: currentName);
  final urlController = TextEditingController(text: currentUrl);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit Favourite'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final url = urlController.text.trim();
            if (name.isNotEmpty && url.isNotEmpty) {
              favouritesBox.putAt(index, {'name': name, 'url': url});
              setState(() {});
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}


  void _removeFavourite(int index) {
    favouritesBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = favouritesBox.values.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20), // ⬅ bring it closer to search bar
      child: Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 30,
          alignment: WrapAlignment.center,
          children: [
            ...List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
  onTap: () async {
    final url = Uri.parse(item['url']);
    if (await canLaunchUrl(url)) launchUrl(url);
  },
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Stack(
        alignment: Alignment.topRight,
        children: [
          const SizedBox(height: 60, width: 60), // Reserve space for alignment
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.lightBlueAccent,
            child: const Icon(Icons.public, color: Colors.black),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _removeFavourite(index);
                } else if (value == 'edit') {
                  _showEditDialog(index, item['name'], item['url']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 16),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 60,
        child: Text(
          item['name'],
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  ),
);

            }),
            GestureDetector(
              onTap: _showAddDialog,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.lightBlueAccent,
                    child: Icon(Icons.add, color: Colors.black),
                  ),
                  SizedBox(height: 6),
                  Text("Add", style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
