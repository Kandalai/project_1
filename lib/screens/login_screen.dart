import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For User Profile
import 'dart:ui'; // For ImageFilter
import 'home_screen.dart';
import 'package:project_1/services/localization_service.dart'; // Import Service

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Added Name Controller
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between Login and Sign Up
  final _loc = LocalizationService(); // Localization

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose(); // Dispose name controller
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Validation
        if (_nameController.text.trim().isEmpty) {
          _showError("Please enter your name");
          return;
        }

        // Create Auth User
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update Auth Profile & Create Firestore Doc
        if (userCredential.user != null) {
          // 1. Update Display Name in Auth
          await userCredential.user!.updateDisplayName(_nameController.text.trim());

          // 2. Create Firestore Profile (Best Effort)
          try {
            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
              'name': _nameController.text.trim(), // Save Name
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'user',
            });
          } catch (e) {
             debugPrint("Firestore profile creation failed: $e");
             // Continue - Auth user is created, so login will still work
          }
        }
      }
      // Success is handled by StreamBuilder in main.dart
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication failed");
    } catch (e) {
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _showError("Guest login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT & GLOWS
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020617), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowCircle(const Color(0xFF00F0FF), 400),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _buildGlowCircle(const Color(0xFF7000FF), 400),
          ),

          // 2. CONTENT
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO / TITLE
                    const Icon(Icons.water_drop, color: Color(0xFF00F0FF), size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      "RainSafe",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "NAVIGATOR",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Rain-Aware Smart Navigation",
                      style: TextStyle(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // GLASS CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              // NAME FIELD (Sign Up Only)
                              if (!_isLogin) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                  hint: _loc.get('name'),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // EMAIL
                              _buildTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                hint: _loc.get('email'),
                              ),
                              const SizedBox(height: 16),
                              
                              // PASSWORD
                              _buildTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hint: _loc.get('password'),
                                isPassword: true,
                              ),
                              const SizedBox(height: 24),

                              // ACTION BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00F0FF),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20, width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                        )
                                      : Text(
                                          _isLogin ? _loc.get('login') : _loc.get('signup'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // TOGGLE TYPE
                              TextButton(
                                onPressed: () => setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin ? _loc.get('signup') : _loc.get('login'),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    // GUEST BUTTON
                    TextButton.icon(
                      onPressed: _isLoading ? null : _handleGuestLogin,
                      icon: const Icon(Icons.person_outline, color: Colors.white54),
                      label: Text(
                        _loc.get('guest'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
