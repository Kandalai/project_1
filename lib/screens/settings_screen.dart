import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_1/screens/login_screen.dart';
import 'package:project_1/theme/app_theme.dart';
import 'package:project_1/services/localization_service.dart'; // Import Service
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  User? _user;
  String _selectedLanguage = 'English';
  final _loc = LocalizationService(); // Helper to access service

  final List<String> _languages = ['English', 'Hindi', 'Telugu', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _loc.currentLanguage; // Sync with service
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      String initialName = _user!.displayName ?? "";
      if (!(_user!.isAnonymous)) {
        try {
           final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
           if (doc.exists && doc.data()!.containsKey('name')) {
             initialName = doc.data()!['name'];
           }
        } catch (e) {
           debugPrint("Error fetching name: $e");
        }
      }
      setState(() {
        _nameController.text = initialName;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // ACTIONS
  // ==========================================

  Future<void> _updateName() async {
    if (_user == null) return;
    
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }

    try {
      await _user!.updateDisplayName(newName);
      if (!_user!.isAnonymous) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'name': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _showSnack(_loc.get('save') + ' Success!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(_loc.get('change_pass'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              decoration: InputDecoration(
                hintText: "Old Password", 
                hintStyle: const TextStyle(color: Colors.white54)
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                hintText: "New Password", 
                hintStyle: const TextStyle(color: Colors.white54)
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_loc.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performPasswordChange();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF)),
            child: Text(_loc.get('save'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordChange() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      _showSnack('Please fill all fields', isError: true);
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(email: _user!.email!, password: oldPass);
      await _user!.reauthenticateWithCredential(cred);
      await _user!.updatePassword(newPass);
      _showSnack('Password changed successfully!');
      _oldPasswordController.clear();
      _newPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Failed', isError: true);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => const LoginScreen()),
         (route) => false,
       );
    }
  }

  // --- ACCOUNT DELETION ---
  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF330000), // Dark Red Warning
        title: Text(_loc.get('delete_account'), style: const TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loc.get('delete_confirm'),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: _loc.get('enter_pass'), 
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_loc.get('cancel'), style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeletion(passwordController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_loc.get('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeletion(String password) async {
    if (password.isEmpty) {
       _showSnack(_loc.get('enter_pass'), isError: true);
       return;
    }
    
    try {
      // 1. Re-authenticate
      final cred = EmailAuthProvider.credential(email: _user!.email!, password: password);
      await _user!.reauthenticateWithCredential(cred);
      
      // 2. Delete Firestore Data (Best Effort)
      try {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).delete();
      } catch (e) {
        debugPrint("Firestore deletion failed (likely permissions): $e");
        // Continue to delete Auth account anyway
      }
      
      // 3. Delete Auth Account
      await _user!.delete();
      
      // 4. Navigate to Login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnack('Deletion Failed: ${e.toString()}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // UI BUILDER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(_loc.get('settings'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020617), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PROFILE AVATAR
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F0FF), Color(0xFF7000FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : 'User',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? '',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // 1. PROFILE SECTION
                Text(_loc.get('profile'), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  children: [
                    _buildTextFieldRow(_loc.get('name'), _nameController, icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F0FF).withOpacity(0.1),
                          foregroundColor: const Color(0xFF00F0FF),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF00F0FF)),
                        ),
                        child: Text(_loc.get('save')),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // 2. ACCOUNT SECURITY
                Text(_loc.get('security'), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline, color: Colors.white70),
                      title: Text(_loc.get('change_pass'), style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                      onTap: _changePassword,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 3. APP SETTINGS
                Text(_loc.get('app_settings'), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language, color: Colors.white70),
                      title: Text(_loc.get('language'), style: const TextStyle(color: Colors.white)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                          items: _languages.map((String lang) {
                            return DropdownMenuItem<String>(
                              value: lang,
                              child: Text(lang),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _loc.setLanguage(newValue); // Update Service
                              setState(() => _selectedLanguage = newValue); // Update UI
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),

                // 4. LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(_loc.get('logout'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                 const SizedBox(height: 24),
                 
                 // 5. DELETE ACCOUNT
                 Center(
                   child: TextButton(
                     onPressed: _deleteAccount,
                     child: Text(
                       _loc.get('delete_account'), 
                       style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                     ),
                   ),
                 ),

                 const SizedBox(height: 16),
                 const Center(
                   child: Text(
                     "Version 1.0.3", 
                     style: TextStyle(color: Colors.white24, fontSize: 12),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextFieldRow(String label, TextEditingController controller, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
              border: InputBorder.none,
              hintText: "",
            ),
          ),
        ),
      ],
    );
  }
}
