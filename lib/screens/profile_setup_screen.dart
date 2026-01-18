import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_selection_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // DRIVER DETAILS
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  bool _isDriver = false;

  // AVATAR
  String _selectedAvatar = "🦉";
  final List<String> _avatars = ["🦉", "🎓", "🚗", "👽", "🦊", "🤖", "⚽", "🎵"];

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) return;
    if (_isDriver &&
        (_carModelController.text.isEmpty ||
            _carPlateController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Drivers must provide car details!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'is_driver': _isDriver,
        'avatar': _selectedAvatar,
        // Car details
        'car_model': _isDriver ? _carModelController.text.trim() : null,
        'car_plate': _isDriver ? _carPlateController.text.trim() : null,
        // Init Stats
        'rating_sum': 0,
        'rating_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.account_circle,
              size: 60,
              color: Color(0xFF531017),
            ),
            const SizedBox(height: 10),
            const Text(
              "Welcome! Let's get you set up.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // AVATAR SELECTOR
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose Avatar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = _selectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatar),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFCC00)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF531017),
                                width: 3,
                              )
                            : null,
                      ),
                      child: Text(avatar, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Standard Info
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone (Optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),
            const Divider(),

            // Driver Toggle
            SwitchListTile(
              title: const Text(
                "I want to Drive others",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Enable this to add vehicle details"),
              value: _isDriver,
              activeColor: const Color(0xFFFFCC00),
              onChanged: (val) => setState(() => _isDriver = val),
            ),

            // Car Details
            if (_isDriver) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _carModelController,
                      decoration: const InputDecoration(
                        labelText: "Car Model (e.g. Silver Honda Civic)",
                        icon: Icon(Icons.directions_car),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _carPlateController,
                      decoration: const InputDecoration(
                        labelText: "License Plate",
                        icon: Icon(Icons.confirmation_number),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("SAVE PROFILE"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
