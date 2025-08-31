class FeedbackEntry {
  final String id;
  final String comment;
  final String mood;
  final String? reply;

  FeedbackEntry({
    required this.id,
    required this.comment,
    required this.mood,
    this.reply,
  });

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['id'],
      comment: map['comment'],
      mood: map['mood'] ?? '',
      reply: map['reply'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comment': comment,
      'mood': mood,
      'reply': reply,
    };
  }
}
