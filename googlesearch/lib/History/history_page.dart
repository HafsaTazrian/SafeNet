import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Screens/search_screen.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final box = await Hive.openBox('history_${user.id}');
      final items = box.values.cast<Map>().toList();

      items.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      setState(() {
        _historyList = items;
      });
    }
  }

  void _openSearch(String query, String ageCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          start: '0',
          searchQuery: query,
          ageCategory: ageCategory,
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search History',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade400,
        elevation: 0,
      ),
      backgroundColor: Colors.blueGrey.shade50,
      body: _historyList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Lottie.asset('assets/animations/No-Data.json'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Oops! No searches yet!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];
                final query = item['query'];
                final ageCategory = item['ageCategory'];

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Card(
                      elevation: 5,
                      shadowColor: Colors.cyan.shade200,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side:
                            BorderSide(color: Colors.teal.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.cyan.shade200,
                          child: Text(
                            query[0].toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          query,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: $ageCategory',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.blueGrey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(item['timestamp']),
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.blueGrey.shade400,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.teal.shade300,
                        ),
                        onTap: () => _openSearch(query, ageCategory),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
