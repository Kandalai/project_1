import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:project_1/screens/home_screen.dart';
import 'package:project_1/screens/login_screen.dart'; // Added LoginScreen
import 'package:project_1/theme/app_theme.dart';

// 1. Remove Async Main
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🚀 STARTUP: Starting RainSafe Navigator...");
  runApp(const RainSafeApp());
}

// 2. Setup Initialization Future
Future<FirebaseApp> _firebaseInit = _initializeFirebase();

Future<FirebaseApp> _initializeFirebase() async {
  try {
    // Try initializing. If it already exists, this might throw or return.
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If it throws "duplicate-app", return the existing instance.
    if (e.toString().contains('duplicate-app')) {
      debugPrint("ℹ️ Firebase already initialized, using existing instance.");
      return Firebase.app();
    }
    // Otherwise rethrow the error
    rethrow;
  }
}

class RainSafeApp extends StatelessWidget {
  const RainSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RainSafe Navigator',
      theme: AppTheme.darkTheme,
      // 3. Use FutureBuilder to wait for Firebase, showing Splash meanwhile
      home: FutureBuilder(
        future: _firebaseInit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, color: Color(0xFF00F0FF), size: 64),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
             return Scaffold(
               backgroundColor: const Color(0xFF0F172A),
               body: Center(
                 child: Text(
                   "Initialization Failed\n${snapshot.error}",
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.red),
                 ),
               ),
             );
          }

          // 4. Once Firebase is ready, check Auth
          return FutureBuilder(
            future: FirebaseAuth.instance.setPersistence(Persistence.LOCAL),
            builder: (context, _) {
              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Color(0xFF0F172A),
                      body: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
                    );
                  }
                  
                  if (authSnapshot.hasData) {
                    debugPrint("✅ USER LOGGED IN: ${authSnapshot.data?.uid}");
                    return const HomeScreen();
                  }
                  
                  debugPrint("⚠️ USER LOGGED OUT");
                  return const LoginScreen();
                },
              );
            }
          );
        },
      ),
    );
  }
}
 /// Entry point of the Rain Safe Navigator application.