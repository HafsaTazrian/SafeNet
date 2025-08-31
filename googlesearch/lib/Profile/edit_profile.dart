import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();

  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Supabase
  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('user_id', user!.id)
        .maybeSingle();

    if (profile != null) {
      _nameController.text = profile['full_name'] ?? '';
      _emailController.text = user.email ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _genderController.text = profile['gender'] ?? '';
      _imageUrl = profile['profile_image_url'];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Pick and upload profile image to Supabase storage
  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final fileName = '${Supabase.instance.client.auth.currentUser!.id}.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

      final publicURL = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'profile_image_url': publicURL})
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

      setState(() {
        _imageUrl = publicURL;
      });
    }
  }

  // Save profile data
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final gender = _genderController.text.trim();

    await Supabase.instance.client.from('profiles').update({
      'full_name': name,
      'age': age,
      'gender': gender,
    }).eq('user_id', Supabase.instance.client.auth.currentUser!.id);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile updated")));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 600,
            height: 500,
           
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile picture with edit icon
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _pickAndUploadImage,
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // Full Name
                _buildTextField("Full Name", _nameController),
                const SizedBox(height: 16),

                // Email (read-only)
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Age
                _buildTextField("Age", _ageController, isNumber: true),
                const SizedBox(height: 16),

                // Gender
                _buildTextField("Gender", _genderController),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save Changes"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom text field builder
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  
}
