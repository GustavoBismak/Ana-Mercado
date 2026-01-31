import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 1));
    
    // Check Shared Preferences
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    String? username = prefs.getString('username');
    final bool isGuest = prefs.getBool('isGuest') ?? false;

    if (!mounted) return;

    if (userId != null && username != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(
          username: username!, 
          userId: userId!,
        )),
      );
    } else {
      // No user found, create a silent Guest account on backend
      final guestData = await ApiService().createGuestUser();
      
      if (guestData != null) {
        // Save guest session so they stay logged in as guest
        await prefs.setInt('userId', guestData['user_id']);
        await prefs.setString('username', guestData['username']);
        await prefs.setString('api_token', guestData['token']);
        await prefs.setBool('isGuest', true);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: 'Convidado',
              userId: guestData['user_id'], // Real ID from backend
              initialDisplayName: 'Convidado',
            ),
          ),
        );
      } else {
         // Fallback if backend offline: still try to show Guest UI (will error on actions)
         // or force Login screen? Let's force Home with -1 but show error snackbar there?
         // Better to just show Home with -1 and let them retry or understand its offline.
         Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(
                username: 'Convidado',
                userId: -1,
                initialDisplayName: 'Convidado (Offline)',
              ),
            ),
          );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or Theme primary color
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display the App Icon
                    // Assuming assets/icon/app_icon.png exists and is configured
                    // App Logo (Icon)
                    const Icon(
                      Icons.shopping_cart_rounded,
                      size: 100,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ana Mercado',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue, // Match primary color
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
