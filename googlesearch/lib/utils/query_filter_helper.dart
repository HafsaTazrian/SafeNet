// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:googlesearch/services/api_service.dart';
import 'package:googlesearch/utils/safety_filter.dart';

class QueryFilterHelper {
  static Future<Map<String, dynamic>> handleQueryAgeAndContent({
    required BuildContext context,
    required String searchQuery,
    required String start,
    required String? ageCategory,
  }) async {
    print("== Query Filter Helper Called ==");
    print("Age category (lowercase): ${ageCategory?.toLowerCase()}");

    // ✅ Get the matched keyword instead of just true/false
    final String? matchedKeyword = await SafetyFilter.getMatchedKeyword(searchQuery);
    final bool isHarmful = matchedKeyword != null;

    print("Is query harmful? $isHarmful");

    if ((ageCategory?.toLowerCase() == 'fifties' || ageCategory?.toLowerCase() == 'twenties') && isHarmful) {
      print("Returning safe filtered results for keyword: $matchedKeyword");

      return {
        'customWidget': true,
        'matchedKeyword': matchedKeyword, // ✅ Add this to be used by your SafeSearchResultCard
      };
    }

    print("Fetching normal API results...");
    final response = await ApiService().fetchData(
      context: context,
      queryTerm: searchQuery,
      start: start,
    );
    print("API results count: ${response['items']?.length ?? 0}");

    return response;
  }
}
