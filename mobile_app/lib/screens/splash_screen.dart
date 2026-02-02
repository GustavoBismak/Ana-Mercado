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
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Duration of the loading
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation
    _controller.forward();

    // Listen for completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuth();
      }
    });
  }

  Future<void> _checkAuth() async {
    try {
      // Check Shared Preferences
      final prefs = await SharedPreferences.getInstance();
      
      int? userId;
      String? username;
      String? displayName;
      String? profilePic;
      
      try {
        userId = prefs.getInt('userId');
        username = prefs.getString('username');
        displayName = prefs.getString('display_name');
        profilePic = prefs.getString('profile_pic');
      } catch (e) {
        await prefs.clear();
        userId = null;
        username = null;
      }

      if (!mounted) return;

      if (userId != null && username != null) {
        // User is logged in -> Go to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(
            username: username!, 
            userId: userId!,
            initialDisplayName: displayName,
            initialProfilePic: profilePic,
          )),
        );
      } else {
        // Not logged in -> Go to Login (User asked to arrive logged in, implying if they WERE, they stay. If not, they need to login.
        // OR, user implies Guest access should be default? "quando abrir já está logado com a conta"
        // If they mean "Remember Me", the above logic handles it.
        // If they mean "Guest Mode auto-login", I will re-implement the generic guest login fallback just in case.
        
        // Actually, the request "when customer login... next time app start... name Ana Mercado... and already logged in"
        // This confirms standard persistent login.
        
        // I will direct to Login Screen if no session found, as that's standard.
        // But referencing the previous code, there was a Guest auto-creation. I'll keep it for robustness if that was the intent,
        // but typically "Login" means the user's actual account. 
        // I'll stick to: If no token, go to LoginScreen. 
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Fallback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    // Screen width for the progress bar calculation
    final double screenWidth = MediaQuery.of(context).size.width;
    final double barWidth = screenWidth * 0.7; // 70% of screen width

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Ana Mercado',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 50),
            
            // Animated Progress Bar with Cart
            SizedBox(
              width: barWidth + 40, // Extra space for icon overflowing
              height: 60,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background Line
                      Positioned(
                        left: 0,
                        top: 29, // vertically centered
                        child: Container(
                          width: barWidth,
                          height: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      
                      // Progress Line
                      Positioned(
                        left: 0,
                        top: 29,
                        child: Container(
                          width: barWidth * _animation.value,
                          height: 2,
                          color: Colors.blue,
                        ),
                      ),
                      
                      // Cart Icon (The "Pulling" effect)
                      Positioned(
                        left: (barWidth * _animation.value) - 15, // centered on tip
                        top: 10,
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
