import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/appointment_provider.dart';
import '../Providers/doctor_provider.dart';
import 'doctor_search_screen.dart';
class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  DateTime? _selectedAppointmentTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctor.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctor.name,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      SizedBox(height: 8),
                      Text('Specialty: ${widget.doctor.specialty}'),
                      Text('Clinic Address: ${widget.doctor.clinicAddress}'),
                      Text('Rating: ${widget.doctor.rating}'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Appointment Time Selection
              Text(
                'Select Appointment Time',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              ElevatedButton(
                child: Text(_selectedAppointmentTime == null
                    ? 'Choose Date & Time'
                    : 'Reschedule'),
                onPressed: () async {
                  final selectedDateTime = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                  );

                  if (selectedDateTime != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (selectedTime != null) {
                      setState(() {
                        _selectedAppointmentTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),

              if (_selectedAppointmentTime != null) ...[
                SizedBox(height: 16),
                Text(
                  'Selected Time: ${_selectedAppointmentTime.toString()}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  child: Text('Book Appointment'),
                  onPressed: () async {
                    final appointmentProvider =
                    Provider.of<AppointmentProvider>(context, listen: false);

                    bool booked = await appointmentProvider.bookAppointment(
                      doctorId: widget.doctor.id,
                      appointmentTime: _selectedAppointmentTime!,
                    );

                    if (booked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appointment Booked Successfully!'))
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appointment Booking Failed. Slot might be occupied.'))
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}