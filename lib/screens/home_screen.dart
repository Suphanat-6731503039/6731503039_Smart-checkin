import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'checkin_screen.dart';
import 'finish_screen.dart';
import 'instructor_dashboard.dart';
import '../qrcode/qr_scanner_screen.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Student';

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient header
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F6AF5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Class',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Classroom Management System',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      // Sign out button
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white70),
                        tooltip: 'Sign out',
                        onPressed: () async {
                          await AuthService.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Greeting
                  Text(
                    'Hello, $name 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'What would you like to do today?',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  // Menu cards
                  _ActionCard(
                    icon: Icons.login_rounded,
                    title: 'Check-in',
                    subtitle: 'Start your class session',
                    gradient: const [Color(0xFF4F6AF5), Color(0xFF6B84F7)],
                    onTap: () =>
                        Navigator.push(context, _route(const CheckInScreen())),
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QR Check-in',
                    subtitle: 'Scan instructor\'s QR code',
                    gradient: const [Color(0xFF7C3AED), Color(0xFF9F67F7)],
                    onTap: () => Navigator.push(
                        context, _route(const QrScannerScreen())),
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Finish Class',
                    subtitle: 'Submit your end-of-class reflection',
                    gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                    onTap: () =>
                        Navigator.push(context, _route(const FinishScreen())),
                  ),
                  const SizedBox(height: 14),
                  _ActionCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Instructor Dashboard',
                    subtitle: 'View attendance & analytics',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    onTap: () => Navigator.push(
                        context, _route(const InstructorDashboard())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
