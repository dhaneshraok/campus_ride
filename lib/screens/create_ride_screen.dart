import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _destinationController = TextEditingController();
  final _exactAddressController = TextEditingController();
  final _publicAreaController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isUrgent = false;

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _postRide() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_destinationController.text.isEmpty ||
        _publicAreaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in destination and pickup area."),
        ),
      );
      return;
    }

    try {
      // 1. Get User Details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final String userName = userDoc.exists
          ? (userDoc['full_name'] ?? "Student")
          : "Student";
      final String userAvatar = userDoc.exists
          ? (userDoc['avatar'] ?? "🦉")
          : "🦉";

      // 2. Create Precise Timestamp for "Vanish" Logic
      final now = DateTime.now();
      // Handle edge case: if selected time is earlier today, assume they mean tomorrow?
      // For MVP, we'll just set it to today's date with the selected time.
      DateTime pickupDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // If the time picked is already passed today, assume it's for tomorrow
      if (pickupDateTime.isBefore(now)) {
        pickupDateTime = pickupDateTime.add(const Duration(days: 1));
      }

      // 3. Upload to Firestore
      await FirebaseFirestore.instance.collection('rides').add({
        'rider_uid': user.uid,
        'rider_name': userName,
        'rider_avatar': userAvatar, // Save avatar to show on card
        'destination': _destinationController.text.trim(),
        'pickup_address': _exactAddressController.text.trim(),
        'pickup_area': _publicAreaController.text.trim(),
        'pickup_time': _selectedTime.format(context), // Display String
        'pickup_datetime':
            pickupDateTime, // Logic Timestamp (for sorting/filtering)
        'is_urgent': _isUrgent,
        'status': 'OPEN',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Cleanup
      _destinationController.clear();
      _exactAddressController.clear();
      _publicAreaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride Requested! 🦉')));
        Navigator.pop(context); // Return to menu
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request a Ride")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.local_taxi, size: 60, color: Color(0xFF531017)),
            const SizedBox(height: 20),

            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: "Where are you going?",
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _publicAreaController,
              decoration: const InputDecoration(
                labelText: "Pickup Area (e.g. Student Center)",
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _exactAddressController,
              decoration: const InputDecoration(
                labelText: "Exact Address (Optional)",
                prefixIcon: Icon(Icons.pin_drop),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              title: Text("Pickup Time: ${_selectedTime.format(context)}"),
              trailing: const Icon(Icons.access_time),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey),
              ),
              onTap: _pickTime,
            ),

            SwitchListTile(
              title: const Text(
                "This is Urgent",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              value: _isUrgent,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => _isUrgent = val),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _postRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF531017),
                  foregroundColor: Colors.white,
                ),
                child: const Text("POST REQUEST"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
