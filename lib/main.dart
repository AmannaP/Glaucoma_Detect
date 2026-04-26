import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/landing.dart';
import 'screens/home_dashboard.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_history.dart';
import 'screens/recommendations.dart';
import 'screens/messages.dart';
import 'screens/profile.dart';
import 'screens/appointment_history.dart';
import 'screens/notifications.dart';
import 'screens/doctor_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
  }
  runApp(const EyeDetectApp());
}

class EyeDetectApp extends StatelessWidget {
  const EyeDetectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00C853);
    
    return MaterialApp(
      title: 'Glaucoma Detect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: primaryGreen),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          brightness: Brightness.dark,
          surface: const Color(0xFF131C24),
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}


class MainNavigationHolder extends StatefulWidget {
  final String? initialRole;
  const MainNavigationHolder({super.key, this.initialRole});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _selectedIndex = 0;
  String _userRole = 'patient';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    if (widget.initialRole != null) {
      setState(() {
        _userRole = widget.initialRole!.trim().toLowerCase();
        _isLoading = false;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = (prefs.getString('user_role') ?? 'patient').trim().toLowerCase();
      _isLoading = false;
    });
  }


  List<Widget> _getPages() {
    if (_userRole == 'doctor') {
      return [
        const DoctorDashboard(),
        const ProfileScreen(),
      ];
    }
    return [
      const HomeDashboard(),
      const ScanHistoryScreen(),
      const AppointmentHistoryScreen(),
      const RecommendationsScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_userRole == 'doctor') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), activeIcon: Icon(Icons.medical_services), label: 'Practice'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Scans'),
      BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), activeIcon: Icon(Icons.event_note), label: 'Appointm...'),
      BottomNavigationBarItem(icon: Icon(Icons.local_hospital_outlined), activeIcon: Icon(Icons.local_hospital), label: 'Doctors'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    const Color primaryGreen = Color(0xFF00C853);
    final pages = _getPages();

    String getTitle() {
      if (_userRole == 'doctor') {
        switch (_selectedIndex) {
          case 0: return "Doctor Portal";
          case 1: return "My Profile";
          default: return "";
        }
      } else {
        switch (_selectedIndex) {
          case 1: return "Scan History";
          case 2: return "Appointments";
          case 3: return "Doctors & Pharmacies";
          case 4: return "My Profile";
          default: return "";
        }
      }
    }

    return Scaffold(
      appBar: (_selectedIndex == 0)
          ? null 
          : AppBar(
              title: Text(getTitle()),
              backgroundColor: Colors.black,
              foregroundColor: primaryGreen,
              elevation: 0,
            ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: primaryGreen,
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          selectedLabelStyle: const TextStyle(fontSize: 10),
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 10,
          items: _getNavItems(),
        ),
      ),
    );
  }
}
