import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googlesearch/Toggle/toggle_switch.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// Main entry point of the application
Future<void> main() async {
  // Ensures all widgets and plugins are initialized before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Loads environment variables from .env file
  await dotenv.load();

  // Initializes Hive local storage and opens required boxes
  await Hive.initFlutter();
  await Hive.openBox('mood_history');
  await Hive.openBox('favourites');
  await Hive.openBox('feedbacks');

  // Initializes Supabase with URL and anon key from environment
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

/// Root widget of the application
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  // Toggles theme mode based on boolean flag
  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provides theme control to all child widgets
    return ThemeController(
      isDark: _themeMode == ThemeMode.dark,
      toggleTheme: _toggleTheme,
      child: Builder(builder: (context) {
        final themeController = ThemeController.of(context);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SafeNet',

          // Dynamically sets theme based on state
          themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,

          // Light theme configuration
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.playfairDisplayTextTheme().apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
            useMaterial3: true,
          ),

          // Dark theme configuration
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: GoogleFonts.playfairDisplayTextTheme().apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.cyan,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          home: const ToggleSwitchPage(),
        );
      }),
    );
  }
}

/// Inherited widget to manage and expose theme state across the app
class ThemeController extends InheritedWidget {
  final bool isDark;
  final void Function(bool) toggleTheme;

  const ThemeController({
    super.key,
    required this.isDark,
    required this.toggleTheme,
    required super.child,
  });

  // Makes ThemeController available in widget tree
  static ThemeController of(BuildContext context) {
    final ThemeController? result =
        context.dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(result != null, 'No ThemeController found in context');
    return result!;
  }

  // Rebuilds widgets only if theme state changes
  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) {
    return isDark != oldWidget.isDark;
  }
}
