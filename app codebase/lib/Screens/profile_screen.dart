import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appointment_scheduling_app/Providers/auth_provider.dart';
import 'LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<MyAuthProvider>(context, listen:false);
    final userProfile = authProvider.currentUserProfile!;

    _nameController = TextEditingController(text: userProfile.name);
    _phoneController = TextEditingController(text: userProfile.phone);
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

    UserProfile updatedProfile = UserProfile(
      uid: authProvider.currentUserProfile!.uid,
      name: _nameController.text.trim(),
      email: authProvider.currentUserProfile!.email,
      phone: _phoneController.text.trim(),
    );

    bool success = await authProvider.updateProfile(updatedProfile);

    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated Successfully'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Update Failed'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final userProfile = authProvider.currentUserProfile;

    if (userProfile == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  _isEditing = true;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: _isEditing
                      ? OutlineInputBorder()
                      : InputBorder.none,
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: _isEditing
                      ? OutlineInputBorder()
                      : InputBorder.none,
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: userProfile.email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: InputBorder.none,
                ),
                enabled: false,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  authProvider.signOut();
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginScreen())
                  );
                },
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}