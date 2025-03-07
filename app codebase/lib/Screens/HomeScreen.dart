import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

// Providers
import 'package:appointment_scheduling_app/Providers/auth_provider.dart';
import 'package:appointment_scheduling_app/Providers/doctor_provider.dart';
import 'package:appointment_scheduling_app/Providers/appointment_provider.dart';

// Screens
import 'doctor_search_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchDoctorsAndLocation();
  }

  Future<void> _fetchDoctorsAndLocation() async {
    // Fetch doctors
    await Provider.of<DoctorProvider>(context, listen: false).fetchDoctors();

    // Get user location
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.'
      );
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
      });

      // Find nearby doctors
      await Provider.of<DoctorProvider>(context, listen: false)
          .findNearbyDoctors(position);
    } catch (e) {
      print('Location Error: $e');
    }
  }

  static List<Widget> _widgetOptions = [
    DoctorSearchScreen(),
    MyAppointmentsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MediGO'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<MyAuthProvider>(context, listen: false).signOut();
            },
          )
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}