import 'dart:convert';
import 'package:flutter/services.dart';

class SafetyFilter {
  // ✅ 1. Load the map instead of a simple list
  static Future<Map<String, dynamic>> _loadSafeContent() async {
    final String jsonString = await rootBundle.loadString('assets/safe_content.json'); // ✅ Changed file name
    final jsonData = json.decode(jsonString);
    return Map<String, dynamic>.from(jsonData); // ✅ Now returns a map instead of a list
  }

  // ✅ 2. Extract keyword list from the JSON map
  static Future<List<String>> loadHarmfulWords() async {
    final contentMap = await _loadSafeContent();
    return contentMap.keys.map((e) => e.toLowerCase()).toList(); // ✅ All keywords
  }

  // ✅ 3. Check if query matches any harmful keyword from the new map
  static Future<String?> getMatchedKeyword(String query) async {
    final harmfulWords = await loadHarmfulWords();
    final lowerQuery = query.toLowerCase();

    for (var word in harmfulWords) {
      if (lowerQuery.contains(word)) {
        print("⚠️ Harmful word detected: $word in query: $query");
        return word; // ✅ Now returns the matched word (not just true/false)
      }
    }
    return null;
  }

  // ✅ Optional: Keep this for compatibility (just true/false)
  static Future<bool> isQueryHarmful(String query) async {
    final matched = await getMatchedKeyword(query);
    return matched != null;
  }
}
