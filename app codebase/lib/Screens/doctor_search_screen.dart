import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:appointment_scheduling_app/Providers/doctor_provider.dart';
import 'package:appointment_scheduling_app/Providers/appointment_provider.dart';

// Screens
import 'doctor_details_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  @override
  _DoctorSearchScreenState createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialty = '';

  final List<String> _specialties = [
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'General Physician'
  ];

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors by name or specialty',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // Implement search logic
              },
            ),
          ),

          // Specialty Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _specialties.map((specialty) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(specialty),
                      selected: _selectedSpecialty == specialty,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedSpecialty = selected ? specialty : '';
                        });
                      },
                    ),
                  )
              ).toList(),
            ),
          ),

          // Nearby Doctors Section
          Expanded(
            child: doctorProvider.nearbyDoctors.isEmpty
                ? Center(child: Text('No nearby doctors found'))
                : ListView.builder(
              itemCount: doctorProvider.nearbyDoctors.length,
              itemBuilder: (context, index) {
                final doctor = doctorProvider.nearbyDoctors[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(doctor.name[0]),
                  ),
                  title: Text(doctor.name),
                  subtitle: Text('${doctor.specialty} | Rating: ${doctor.rating}'),
                  trailing: ElevatedButton(
                    child: Text('Book'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(doctor: doctor),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

