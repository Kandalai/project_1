import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User ID
import 'package:cloud_firestore/cloud_firestore.dart'; // For User Name
import 'dart:async'; // For Timer
import 'dart:math'; // For min function
import 'dart:ui'; // For ImageFilter
import 'map_screen.dart';
import '../services/api_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'package:project_1/services/localization_service.dart'; // Import Service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  final _searchController = TextEditingController();
  final _loc = LocalizationService(); // Localization
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Real Data State
  String _displayId = "Guest"; // Default to Guest
  Map<String, dynamic>? _weatherData;
  List<String> _searchHistory = [];
  List<SearchResult> _searchResults = [];
  bool _isLoadingWeather = true;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 0. Fetch User Info (Name or ID)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String displayName = "Guest";
        
        // A. Try Auth Profile Name
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          displayName = user.displayName!;
        } 
        // B. Try Firestore Profile Name
        else if (!user.isAnonymous) {
             final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
             if (doc.exists && doc.data()!.containsKey('name')) {
               displayName = doc.data()!['name'];
             }
        }
        
        // C. Fallback to ID
        if (displayName == "Guest" && !user.isAnonymous) {
           displayName = "ID: ${user.uid.substring(0, min(6, user.uid.length))}...";
        }

        if (mounted) {
            setState(() {
                _displayId = displayName; // Now holds "Name" or "ID: 123..."
            });
        }
      }
    } catch (e) {
      print("Error fetching user info: $e");
    }

    // 1. Fetch History
    final history = await api.getSearchHistory();
    if (mounted) setState(() => _searchHistory = history);

    // 2. Fetch Weather
    try {
      final loc = await api.getCurrentLocation();
      if (loc != null) {
        final weather = await api.getWeatherAtLocation(loc);
        if (mounted) {
            setState(() {
                _weatherData = weather;
                _isLoadingWeather = false;
            });
        }
      } else {
         if (mounted) setState(() => _isLoadingWeather = false);
      }
    } catch (e) {
      print("Error loading weather: $e");
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = _searchController.text;
      if (query.length > 2) {
        setState(() => _isSearching = true);
        final results = await api.getPlaceSuggestions(query);
        if (mounted) setState(() => _searchResults = results);
      } else {
        if (mounted) {
            setState(() {
                _isSearching = false;
                _searchResults = [];
            });
        }
      }
    });
  }

  void _navigateToMap(String destination) async {
      // 1. Save to history
      await api.addToHistory(destination);

      // 2. Get coords
      final coords = await api.getCoordinates(destination);
      if (coords != null && mounted) {
           // 3. Push Map Screen and refresh history on return
           await Navigator.push(
               context,
               MaterialPageRoute(
                   builder: (_) => MapScreen(
                     startPoint: "Current Location",
                     endPoint: destination,
                     endCoords: coords,
                   ),
               ),
           );
           // 4. Refresh search history when user comes back
           final history = await api.getSearchHistory();
           if (mounted) setState(() => _searchHistory = history);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fallback
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020617), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // 2. AMBIENT NEON GLOWS
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowCircle(const Color(0xFF00F0FF), 400), // Cyan Glow (Top Right)
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildGlowCircle(const Color(0xFF7000FF), 350), // Purple Glow (Bottom Left)
          ),

          // 3. MAIN DASHBOARD CONTENT
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // SEARCH BAR (Floating)
                    _buildSearchBar(),
                    const SizedBox(height: 32),

                    // WEATHER WIDGET (Premium Glass)
                    _buildWeatherWidget(),
                    const SizedBox(height: 32),

                    // SAVED ROUTES TITLE
                    Text(
                      _loc.get('recent_searches'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SAVED ROUTES LIST
                    _buildSavedRoutesList(),
                    const SizedBox(height: 32),
                    
                    // START ACTION
                    _buildStartButton(context),
                  ],
                ),
              ),
            ),
          ),

          // 4. SEARCH RESULTS OVERLAY
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: 260, // Adjusted to sit below the search bar 
              left: 24, 
              right: 24,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: _searchResults.length,
                      separatorBuilder: (ctx, i) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                      itemBuilder: (ctx, i) {
                        final result = _searchResults[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF00F0FF)),
                          title: Text(
                             result.name,
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                             result.address,
                             style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                          ),
                          onTap: () {
                             _navigateToMap(result.fullText);
                             setState(() {
                               _isSearching = false;
                               _searchController.clear();
                             });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loc.get('welcome'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _displayId, 
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Slightly smaller to fit ID
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const SettingsScreen())
            );
            _loadData(); // Refresh name upon return
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
              image: const DecorationImage(
                image: NetworkImage("https://i.pravatar.cc/150?img=12"), // Placeholder Avatar
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _loc.get('search_hint'),
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _navigateToMap(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
             onTap: () {
               if (_searchController.text.trim().isNotEmpty) {
                 _navigateToMap(_searchController.text.trim());
               }
             },
             child: const Icon(Icons.search, color: Colors.white54),
          ),

        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    if (_isLoadingWeather) {
       return const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)));
    }

    final weatherCode = _weatherData?['weathercode'] as int? ?? 0;
    final temp = _weatherData?['temperature_2m'] ?? 0.0;
    final desc = api.getWeatherDescription(weatherCode);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loc.get('current_cond'),
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                   Text(
                    "${temp.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ],
              ),
              if (desc.contains("Rain") || desc.contains("Storm")) ...[
                 const SizedBox(height: 24),
                 // ALERTS
                 _buildAlertPill("Potential Slippery Roads", const Color(0xFFFF9500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertPill(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color, // Text matches alert color
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRoutesList() {
    if (_searchHistory.isEmpty) {
        return const Center(child: Text("No recent searches", style: TextStyle(color: Colors.white38)));
    }

    return SizedBox(
      height: 140, // Height for saved route cards
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        clipBehavior: Clip.none,
        itemCount: _searchHistory.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) {
           final item = _searchHistory[i];
           return GestureDetector(
             onTap: () => _navigateToMap(item),
             child: _buildSavedRouteCard(item, "Recent", Icons.history, true),
           );
        },
      ),
    );
  }

  Widget _buildSavedRouteCard(String title, String distance, IconData icon, bool isSafe) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border.all(
             color: isSafe ? const Color(0xFF00FF9D).withValues(alpha: 0.3) : Colors.white10
        ),
        boxShadow: [
           if (isSafe) BoxShadow(
             color: const Color(0xFF00FF9D).withValues(alpha: 0.1),
             blurRadius: 20,
             spreadRadius: 0,
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70),
              if (isSafe)
                 const Icon(Icons.check_circle, color: Color(0xFF00FF9D), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                distance,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 20,
          shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.4),
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MapScreen(
                startPoint: "Current Location",
                endPoint: "",
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  _loc.get('search_btn'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
