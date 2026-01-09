import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for existing user session
  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('userId');
  final String? username = prefs.getString('username');
  final String? profilePic = prefs.getString('profile_pic');
  final String? displayName = prefs.getString('display_name');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: AnaMercadoApp(
        initialUserId: userId,
        initialUsername: username,
        initialProfilePic: profilePic,
        initialDisplayName: displayName,
      ),
    ),
  );
}

class AnaMercadoApp extends StatelessWidget {
  final int? initialUserId;
  final String? initialUsername;
  final String? initialProfilePic;
  final String? initialDisplayName;

  const AnaMercadoApp({
    super.key,
    this.initialUserId,
    this.initialUsername,
    this.initialProfilePic,
    this.initialDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Determine initial Screen
    // If no user found, startup as Guest (userId: -1) instead of LoginScreen
    // User can choose to login later from Home
    final Widget homeScreen;
    if (initialUserId != null) {
        homeScreen = HomeScreen(
          username: initialUsername!, 
          userId: initialUserId!,
          initialProfilePic: initialProfilePic,
          initialDisplayName: initialDisplayName,
        );
    } else {
        // Guest Mode
        homeScreen = const HomeScreen(
          username: 'Convidado',
          userId: -1, 
          initialDisplayName: 'Convidado',
        );
    }

    return MaterialApp(
      title: 'Ana Mercado',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Dark background
        appBarTheme: const AppBarTheme(
          color: Color(0xFF1E1E1E), // Match scaffold or slightly lighter
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF2C2C2C), // Lighter card for dark mode
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: homeScreen,
    );
  }
}
