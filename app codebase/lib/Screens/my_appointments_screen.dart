import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:appointment_scheduling_app/Providers/appointment_provider.dart';
import 'package:appointment_scheduling_app/Providers/doctor_provider.dart';

class MyAppointmentsScreen extends StatefulWidget {
  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false)
          .fetchUserAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final doctorProvider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments'),
      ),
      body: appointmentProvider.userAppointments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Appointments Scheduled',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: appointmentProvider.userAppointments.length,
        itemBuilder: (context, index) {
          final appointment = appointmentProvider.userAppointments[index];

          // Find the doctor for this appointment
          final doctor = doctorProvider.doctors.firstWhere(
                  (doc) => doc.id == appointment.doctorId,
              orElse: () => Doctor(
                  id: '',
                  name: 'Unknown Doctor',
                  specialty: '',
                  clinicAddress: '',
                  location: GeoPoint(0, 0),
                  availableSlots: [],
                  rating: 0.0
              )
          );

          return AppointmentCard(
            appointment: appointment,
            doctor: doctor,
            onCancel: () {
              _showCancelConfirmation(context, appointment);
            },
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppointmentProvider>(context, listen: false)
                  .cancelAppointment(appointment.id);
              Navigator.of(context).pop();
            },
            child: Text('Yes, Cancel'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Doctor doctor;
  final VoidCallback onCancel;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.doctor,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctor.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Specialty: ${doctor.specialty}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(appointment.appointmentTime),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(appointment.appointmentTime),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement directions to clinic
                  },
                  icon: Icon(Icons.directions),
                  label: Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancel Appointment',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}