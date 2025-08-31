import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AddFavouriteDialog extends StatefulWidget {
  const AddFavouriteDialog({super.key});

  @override
  State<AddFavouriteDialog> createState() => _AddFavouriteDialogState();
}

class _AddFavouriteDialogState extends State<AddFavouriteDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  bool _saving = false;

  Future<void> _saveFavourite() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) return;

    setState(() => _saving = true);

    final box = await Hive.openBox('favourites');
    await box.add({
      'name': name,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context); // close dialog
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Favourite'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveFavourite,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
