import 'package:appointment_scheduling_app/services/Notificationservices.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class Appointment {
  final String id;
  final String doctorId;
  final String userId;
  final DateTime appointmentTime;
  final String status;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.appointmentTime,
    required this.status,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      userId: data['userId'] ?? '',
      appointmentTime: (data['appointmentTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }
}

class AppointmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  AppointmentProvider() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  List<Appointment> _userAppointments = [];
  List<Appointment> get userAppointments => _userAppointments;

  Future<bool> bookAppointment({
    required String doctorId,
    required DateTime appointmentTime,
  }) async {
    try {
      // Check for conflicting appointments
      QuerySnapshot conflictCheck = await _firestore.collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentTime', isEqualTo: appointmentTime)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      if (conflictCheck.docs.isNotEmpty) {
        return false; // Appointment slot already booked
      }

      // Book new appointment
      DocumentReference appointmentRef = await _firestore.collection('appointments').add({
        'doctorId': doctorId,
        'userId': _auth.currentUser!.uid,
        'appointmentTime': appointmentTime,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Schedule local notification
      await _scheduleAppointmentReminder(appointmentRef.id, appointmentTime);

      return true;
    } catch (e) {
      print('Booking Appointment Error: $e');
      return false;
    }
  }

  Future<void> _scheduleAppointmentReminder(String appointmentId, DateTime appointmentTime) async {
    // Configure notification details
    DateTime reminderTime = appointmentTime.subtract(Duration(hours: 1));

    await _notificationService.scheduleAppointmentReminder(
      id: appointmentId.hashCode,
      title: 'Upcoming Appointment',
      body: 'Your appointment is in 1 hour',
      scheduledTime: reminderTime,
    );
  }

  Future<void> fetchUserAppointments() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('appointments')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('appointmentTime')
          .get();

      _userAppointments = snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Fetching Appointments Error: $e');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
      });

      // Remove local notification
      await _notificationService.cancelNotification(appointmentId.hashCode);

      await fetchUserAppointments();
    } catch (e) {
      print('Cancel Appointment Error: $e');
    }
  }
}