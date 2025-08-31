// ignore_for_file: use_super_parameters, prefer_const_constructors, sort_child_properties_last

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googlesearch/Appbar/user_appbar.dart';

import 'package:googlesearch/utils/safe_search_result.dart';
import 'package:googlesearch/utils/query_filter_helper.dart';
import 'package:googlesearch/web/web_search_header.dart';
import 'package:googlesearch/widgets/search_footer.dart';

import 'package:googlesearch/widgets/search_result_component.dart';

class SearchScreen extends StatelessWidget {
  // Search query string to search for
  final String searchQuery;

  // Pagination start index as string (e.g. "0", "10", "20")
  final String start;

  // Optional age category from voice input
  final String? ageCategory;

  const SearchScreen({
    Key? key,
    required this.searchQuery,
    this.start = '0',
    this.ageCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Title(
        color: Colors.blue,
        title: searchQuery,
        child: Scaffold(
          appBar: UserAppBar(), // Custom app bar widget
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header showing current search query
                WebSearchHeader(searchQuery: searchQuery),

                // If age category is provided, show it below header
                if (ageCategory != null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: size.width <= 768 ? 10 : 150.0,
                      top: 8.0,
                    ),
                    child: Text(
                      'Voice Age Category: $ageCategory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const Divider(thickness: 0),

                // FutureBuilder to handle async search API call & filtering
                FutureBuilder<Map<String, dynamic>>(
                  future: QueryFilterHelper.handleQueryAgeAndContent(
                    context: context,
                    searchQuery: searchQuery,
                    start: start,
                    ageCategory: ageCategory,
                  ),
                  builder: (context, snapshot) {
                    // Loading spinner while waiting
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Show error message if any error occurs
                    else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    // Show message if no data received
                    else if (!snapshot.hasData) {
                      return const Center(child: Text('No data found.'));
                    }

                    final data = snapshot.data!;

                    // Check if response indicates to show a custom safe content widget
                    if (data['customWidget'] == true && data['matchedKeyword'] != null) {
                      final matchedKeyword = data['matchedKeyword'];

                      // Load safe content JSON file from assets
                      return FutureBuilder<Map<String, dynamic>>(
                        future: rootBundle
                            .loadString('assets/safe_content.json')
                            .then((jsonStr) => json.decode(jsonStr)),
                        builder: (context, safeSnapshot) {
                          if (safeSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (safeSnapshot.hasError || !safeSnapshot.hasData) {
                            return const Center(child: Text('Error loading safety content.'));
                          }

                          final content = safeSnapshot.data![matchedKeyword];
                          if (content == null) {
                            return const Center(child: Text('No safe content available.'));
                          }

                          // Display safe search result card with matched content
                          return SafeSearchResultCard(
                            title: content['title'],
                            description: content['description'],
                            imageUrl: content['image'],
                            matchedKeyword: content['matchedKeyword'],
                            ageCategory:ageCategory ?? '',
                            resources: (content['resources'] as List)
                                .map((e) => {
                                      'label': e['label'].toString(),
                                      'url': e['url'].toString(),
                                    })
                                .toList(),
                          );
                        },
                      );
                    }

                    // Otherwise, show normal search results list
                    final items = data['items'];
                    if (items == null || items.isEmpty) {
                      return const Center(child: Text('No results found.'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show total results count and search time
                        Padding(
                          padding: EdgeInsets.only(left: size.width <= 768 ? 10 : 150, top: 12),
                          child: Text(
                            "About ${data['searchInformation']['formattedTotalResults']} results (${data['searchInformation']['formattedSearchTime']} seconds)",
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),

                        // List of search results scrollable area
                        SizedBox(
                          height: size.height * 0.7,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: size.width <= 768 ? 10 : 100),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              // Extract image URL if present
                              String? imageUrl;
                              if (item['pagemap'] != null && item['pagemap']['cse_image'] != null) {
                                imageUrl = item['pagemap']['cse_image'][0]['src'];
                              }

                              return SearchResultComponent(
                                linkToGo: item['link'] ?? '',
                                link: item['formattedUrl'] ?? '',
                                text: item['title'] ?? 'No title',
                                desc: item['snippet'] ?? '',
                                imageUrl: imageUrl ?? '',
                                ageCategory: ageCategory ?? '',
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Pagination buttons for Prev and Next pages
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Previous page button (disabled if on first page)
                              TextButton(
                                child: const Text("< Prev", style: TextStyle(fontSize: 15)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: start != "0"
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchScreen(
                                              searchQuery: searchQuery,
                                              start: (int.parse(start) - 10).toString(),
                                              ageCategory: ageCategory,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                              ),

                              const SizedBox(width: 30),

                              // Next page button
                              TextButton(
                                child: const Text("Next >", style: TextStyle(fontSize: 15)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchScreen(
                                        searchQuery: searchQuery,
                                        start: (int.parse(start) + 10).toString(),
                                        ageCategory: ageCategory,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Footer widget at bottom
                        const SearchFooter(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
