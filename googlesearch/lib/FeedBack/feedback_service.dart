import 'package:googlesearch/FeedBack/feedback_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';


class FeedbackService {
  final _box = Hive.box('feedbacks');

  Future<void> submitFeedback(String comment, String mood) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await Supabase.instance.client
        .from('feedback')
        .insert({
          'user_id': user.id,
          'comment': comment,
          'mood': mood,
        })
        .select()
        .single();

    final feedbackEntry = FeedbackEntry.fromMap(response);
    await _box.put(feedbackEntry.id, feedbackEntry.toMap());
  }

  Future<List<FeedbackEntry>> fetchUserFeedbacks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('feedback')
        .select()
        .eq('user_id', user.id);

    final List data = response as List;

    for (final fb in data) {
      final entry = FeedbackEntry.fromMap(fb);
      await _box.put(entry.id, entry.toMap());
    }

    final entries = data.map((e) => FeedbackEntry.fromMap(e)).toList();
    entries.sort((a, b) => b.id.compareTo(a.id));
    return entries;
  }

  List<FeedbackEntry> getCachedFeedbacks() {
    final all = _box.values.toList();
    return all.map((e) => FeedbackEntry.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}
