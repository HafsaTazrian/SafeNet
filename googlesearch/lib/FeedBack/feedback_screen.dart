// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/FeedBack/feedback_entry.dart';
import 'package:googlesearch/FeedBack/feedback_service.dart';
import 'package:lottie/lottie.dart';


class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _moodController = TextEditingController();
  final FeedbackService _service = FeedbackService();

  List<FeedbackEntry> _feedbackList = [];
  bool _isLoading = false;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    await _service.fetchUserFeedbacks();
    final cached = _service.getCachedFeedbacks();
    setState(() {
      _feedbackList = cached;
      _isLoading = false;
    });
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final comment = _commentController.text.trim();
    final mood = _moodController.text.trim();

    try {
      await _service.submitFeedback(comment, mood);
      _commentController.clear();
      _moodController.clear();
      await _loadFeedbacks();

      // ✅ Show success animation
      setState(() => _showSuccessAnimation = true);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _showSuccessAnimation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('Feedback',style: GoogleFonts.playfairDisplay(color: Colors.blueGrey),)),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 📝 Feedback Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Your feedback',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter feedback' : null,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _moodController,
                        decoration: const InputDecoration(
                          labelText: 'Mood (optional, e.g., 😊)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _submitFeedback,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🗂 Feedback list
                _isLoading
                    ? const CircularProgressIndicator()
                    : Expanded(
                        child: _feedbackList.isEmpty
                            ? const Center(child: Text('No feedback yet'))
                            : ListView.builder(
                                itemCount: _feedbackList.length,
                                itemBuilder: (context, index) {
                                  final fb = _feedbackList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("🧒 You said: ${fb.comment}",
                                              style: const TextStyle(fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text("Mood: ${fb.mood}",
                                              style: const TextStyle(color: Colors.grey)),
                                          if (fb.reply != null) ...[
                                            const Divider(height: 20),
                                            Text("👩‍🏫 Reply: ${fb.reply}",
                                                style: const TextStyle(color: Colors.blue)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ],
            ),
          ),

          // 🎉 Fullscreen Success Animation (centered)
          if (_showSuccessAnimation)
            Container(
              color: Colors.black54,
              child: Center(
                child: Lottie.asset(
                  'assets/animations/success.json', 
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
