import 'package:flutter/material.dart';

/// Splash screen shown during app cold-start.
///
/// Displays a branded logo / animation while initialization completes,
/// then navigates to the appropriate next screen (onboarding, login,
/// or dashboard) via the router's redirect logic.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Minimum branding animation (800ms) — the router's redirect logic
    // will navigate away once auth state is resolved. This ensures the
    // splash is visible briefly for branding, without an arbitrary 2s
    // delay that blocks users on fast connections/devices.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    // Navigation is handled by GoRouter redirect logic.
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 72),
            SizedBox(height: 16),
            Text(
              'ExamForge AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
