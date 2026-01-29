import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:project_1/screens/map_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Authenticate SECOND (Unlocks the database for the Liar Algorithm)
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint("✅ RainSafe Apex: Anonymous Auth Successful");
  } catch (e) {
    debugPrint("❌ Auth Error: $e");
  }

  runApp(const RainSafeApp());
}

class RainSafeApp extends StatelessWidget {
  const RainSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RainSafe Navigator',
      // High-Contrast Theme for visibility in rain/glare
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _startController =
      TextEditingController(text: "Current Location");
  final TextEditingController _endController = TextEditingController();

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RainSafe Navigator"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Plan Your Safe Route",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Avoiding floods and high-risk dips automatically.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              // Start location input
              _buildInputCard(
                controller: _startController,
                hint: "From: Current Location",
                icon: Icons.my_location,
                iconColor: Colors.greenAccent,
              ),
              
              const SizedBox(height: 16),
              
              // End location input
              _buildInputCard(
                controller: _endController,
                hint: "To: Enter Destination City",
                icon: Icons.location_on,
                iconColor: Colors.redAccent,
              ),
              
              const SizedBox(height: 40),
              
              // Navigate button
              SizedBox(
                width: double.infinity,
                height: 60, // Taller for glove-friendly use
                child: ElevatedButton(
                  onPressed: _onFindRoutePressed,
                  child: const Text(
                    "FIND SAFE ROUTE",
                    style: TextStyle(fontSize: 18, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E1E1E),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  void _onFindRoutePressed() {
    final String start = _startController.text.trim();
    final String end = _endController.text.trim();

    if (end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a destination city"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Pass data to MapScreen for GIS processing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          startPoint: start.isEmpty ? "Current Location" : start,
          endPoint: end,
        ),
      ),
    );
  }
} /// Entry point of the Rain Safe Navigator application.