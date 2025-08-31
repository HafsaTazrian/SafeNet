import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googlesearch/Screens/search_screen.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class KidsHistoryPage extends StatefulWidget {
  const KidsHistoryPage({super.key});

  @override
  State<KidsHistoryPage> createState() => _KidsHistoryPageState();
}

class _KidsHistoryPageState extends State<KidsHistoryPage> {
  List<Map> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadTeenHistory();
  }

  Future<void> _loadTeenHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final box = await Hive.openBox('history_${user.id}');
      final allItems = box.values.cast<Map>().toList();

      // Filter only for teen ageCategory
      final teenItems = allItems
    .where((item) => 
        item['ageCategory']?.toString().toLowerCase().trim() == 'fifties' || 
        item['ageCategory']?.toString().toLowerCase().trim() == 'twenties')
    .toList();

      teenItems.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      setState(() {
        _historyList = teenItems;
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
          'Your Safe History',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade400,
        elevation: 0,
      ),
      backgroundColor: Colors.deepPurple.shade50,
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
                    'No safe searches yet!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade300,
                      decoration: TextDecoration.none
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
                      shadowColor: Colors.deepPurple.shade200,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Colors.deepPurple.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.deepPurple.shade200,
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
                            decoration: TextDecoration.none
                          ),
                        ),
                        subtitle: Text(
                          _formatTimestamp(item['timestamp']),
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.blueGrey.shade400,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.none
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.deepPurple.shade300,
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
