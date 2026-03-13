import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Quick login credentials (demo)
  final String _quickEmail = 'demo@student.com';
  final String _quickPass = 'demopass';

  Future<void> _quickLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(email: _quickEmail, password: _quickPass);
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      _snack('Quick login failed', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ...existing code...
  late final TabController _tab;
  bool _isLoading = false;
  bool _obscure = true;

  // Login
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  // Register
  final _regName = TextEditingController();
  final _regStudentId = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regStudentId.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.trim().isEmpty || _loginPass.text.isEmpty) {
      _snack('Please fill in all fields', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        email: _loginEmail.text.trim(),
        password: _loginPass.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on Exception catch (e) {
      _snack(_friendlyError(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (_regName.text.trim().isEmpty ||
        _regEmail.text.trim().isEmpty ||
        _regPass.text.isEmpty) {
      _snack('Please fill in all required fields', error: true);
      return;
    }
    if (_regPass.text.length < 6) {
      _snack('Password must be at least 6 characters', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        email: _regEmail.text.trim(),
        password: _regPass.text,
        displayName: _regName.text.trim(),
        studentId: _regStudentId.text.trim(),
        role: _role,
      );
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on Exception catch (e) {
      _snack(_friendlyError(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('email-already-in-use')) return 'Email already in use.';
    if (e.contains('wrong-password') || e.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (e.contains('user-not-found')) return 'No account with this email.';
    if (e.contains('invalid-email')) return 'Invalid email address.';
    if (e.contains('weak-password')) return 'Password is too weak.';
    return 'Something went wrong. Please try again.';
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor:
          error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Quick Login Button UI
    Widget quickLoginBtn = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF4F6AF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isLoading ? null : _quickLogin,
          child: SizedBox(
            height: 56,
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text('Quick Login',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F6AF5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo + title
                const Icon(Icons.school_rounded, color: Colors.white, size: 52),
                const SizedBox(height: 12),
                const Text('Smart Class',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                const Text('Classroom Management System',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 32),
                // Quick Login Button
                quickLoginBtn,
                // Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _tab,
                              indicator: BoxDecoration(
                                color: const Color(0xFF4F6AF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Login'),
                                Tab(text: 'Register'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _loginForm(),
                              _registerForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _field(_loginEmail, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _passField(_loginPass, 'Password'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot password?',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6AF5))),
            ),
          ),
          const SizedBox(height: 8),
          _submitBtn('Login', _login),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _field(_regName, 'Full Name', Icons.person_outline),
          const SizedBox(height: 14),
          _field(_regStudentId, 'Student ID', Icons.badge_outlined),
          const SizedBox(height: 14),
          _field(_regEmail, 'Email', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _passField(_regPass, 'Password (min 6 chars)'),
          const SizedBox(height: 14),
          // Role selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.manage_accounts_outlined,
                    color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 10),
                const Text('Role',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Spacer(),
                DropdownButton<String>(
                  value: _role,
                  underline: const SizedBox(),
                  style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'instructor', child: Text('Instructor')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _submitBtn('Create Account', _register),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint) {
    return StatefulBuilder(
      builder: (_, setLocal) => TextField(
        controller: ctrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
              const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F6AF5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_loginEmail.text.trim().isEmpty) {
      _snack('Enter your email first', error: true);
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _loginEmail.text.trim());
      _snack('Reset email sent! Check your inbox.');
    } catch (_) {
      _snack('Could not send reset email.', error: true);
    }
  }
}
