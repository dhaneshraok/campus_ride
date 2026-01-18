import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();

  bool _isDriver = false;
  bool _isLoading = true;
  String _selectedAvatar = "🦉"; // Default Avatar (Owl)

  // List of available avatars
  final List<String> _avatars = ["🦉", "🎓", "🚗", "👽", "🦊", "🤖", "⚽", "🎵"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['full_name'] ?? "";
        _phoneController.text = data['phone'] ?? "";
        _isDriver = data['is_driver'] ?? false;
        _carModelController.text = data['car_model'] ?? "";
        _carPlateController.text = data['car_plate'] ?? "";
        _selectedAvatar = data['avatar'] ?? "🦉"; // Load saved avatar
        _isLoading = false;
      });
    }
  }

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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'is_driver': _isDriver,
          'car_model': _isDriver ? _carModelController.text.trim() : null,
          'car_plate': _isDriver ? _carPlateController.text.trim() : null,
          'avatar': _selectedAvatar, // Save the emoji
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        Navigator.pop(context); // Go back to Menu
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
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // AVATAR SELECTOR
                  const Text(
                    "Choose your Avatar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
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
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 24),
                            ),
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

                  // Car Details (Hidden unless Driver is True)
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("UPDATE PROFILE"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
