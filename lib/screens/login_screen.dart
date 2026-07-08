// lib/screens/login_screen.dart
// Firebase-backed login & registration for AgriSense farmers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _pinObscured = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedLanguage = 'English';

  late AnimationController _logoAnimCtrl;
  late Animation<double> _logoFadeAnim;
  late Animation<Offset> _logoSlideAnim;

  final List<String> _languages = ['English', 'हिंदी', 'తెలుగు', 'தமிழ்', 'मराठी'];

  @override
  void initState() {
    super.initState();
    _logoAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoAnimCtrl, curve: Curves.easeOut),
    );
    _logoSlideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _logoAnimCtrl, curve: Curves.easeOut),
    );
    _logoAnimCtrl.forward();
  }

  @override
  void dispose() {
    _logoAnimCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final (success, msg) = _isSignUp
        ? await AuthService.register(
            name: _nameCtrl.text,
            mobile: _mobileCtrl.text,
            pin: _pinCtrl.text,
            language: _selectedLanguage,
          )
        : await AuthService.login(
            _mobileCtrl.text,
            _pinCtrl.text,
            _selectedLanguage,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final profile = await AuthService.getProfile();
      if (!mounted) return;
      _showWelcomeToast(profile.name);
      widget.onLoginSuccess();
    } else {
      setState(() => _errorMessage = msg);
      HapticFeedback.lightImpact();
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = '';
    });
  }

  void _showWelcomeToast(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E5E4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome${_isSignUp ? '' : ' back'}, $name! 🌱',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              SlideTransition(
                position: _logoSlideAnim,
                child: FadeTransition(
                  opacity: _logoFadeAnim,
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E5E4A), Color(0xFF2D8A6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E5E4A).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'AgriSense',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF123C32),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Smart Farming Assistant',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 44),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account 🌾' : 'Welcome Back 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF123C32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? 'Register with your mobile to start farming smarter'
                          : 'Sign in to continue to your farm dashboard',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    if (_isSignUp) ...[
                      _buildLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          hint: 'Your name',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      decoration: _inputDecoration(
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 4),

                    _buildLabel('6-Digit PIN'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pinCtrl,
                      obscureText: _pinObscured,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      decoration: _inputDecoration(
                        hint: '••••••',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _pinObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _pinObscured = !_pinObscured),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    _buildLabel('Preferred Language'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E5E4A)),
                          items: _languages
                              .map(
                                (lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.translate, size: 16, color: Color(0xFF1E5E4A)),
                                      const SizedBox(width: 8),
                                      Text(lang, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _selectedLanguage = val ?? _selectedLanguage),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Login',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _toggleMode,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                            children: [
                              TextSpan(
                                text: _isSignUp ? 'Already have an account? ' : 'New farmer? ',
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Login' : 'Create account',
                                style: const TextStyle(
                                  color: Color(0xFF1E5E4A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 16, color: Color(0xFF1E5E4A)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your account is securely stored in Firebase. Use any new mobile number and 6-digit PIN to register.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E5E4A)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E352C),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1E5E4A), size: 20),
        suffixIcon: suffix,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E5E4A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}
