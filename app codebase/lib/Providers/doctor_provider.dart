import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String clinicAddress;
  final GeoPoint location;
  final List<String> availableSlots;
  final double rating;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinicAddress,
    required this.location,
    required this.availableSlots,
    required this.rating,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Doctor(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      clinicAddress: data['clinicAddress'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      availableSlots: List<String>.from(data['availableSlots'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }
}

class DoctorProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Doctor> _doctors = [];
  List<Doctor> _nearbyDoctors = [];

  List<Doctor> get doctors => _doctors;
  List<Doctor> get nearbyDoctors => _nearbyDoctors;

  Future<void> fetchDoctors() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('doctors').get();
      _doctors = snapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching doctors: $e');
    }
  }

  Future<void> findNearbyDoctors(Position userLocation, {double radius = 10}) async {
    try {
      _nearbyDoctors = _doctors.where((doctor) {
        double distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            doctor.location.latitude,
            doctor.location.longitude
        ) / 1000; // Convert to kilometers

        return distance <= radius;
      }).toList();

      // Sort doctors by distance
      _nearbyDoctors.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            a.location.latitude,
            a.location.longitude
        );
        double distanceB = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            b.location.latitude,
            b.location.longitude
        );
        return distanceA.compareTo(distanceB);
      });

      notifyListeners();
    } catch (e) {
      print('Error finding nearby doctors: $e');
    }
  }

  Future<List<Doctor>> searchDoctorsBySpecialty(String specialty) async {
    try {
      return _doctors.where((doctor) =>
          doctor.specialty.toLowerCase().contains(specialty.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error searching doctors: $e');
      return [];
    }
  }
}