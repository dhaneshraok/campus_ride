import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRideScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> currentData;

  const EditRideScreen({
    super.key,
    required this.rideId,
    required this.currentData,
  });

  @override
  State<EditRideScreen> createState() => _EditRideScreenState();
}

class _EditRideScreenState extends State<EditRideScreen> {
  late TextEditingController _destinationController;
  late TextEditingController _pickupController;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(
      text: widget.currentData['destination'],
    );
    _pickupController = TextEditingController(
      text: widget.currentData['pickup_area'],
    );
  }

  Future<void> _updateRide() async {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
          'destination': _destinationController.text,
          'pickup_area': _pickupController.text,
          'pickup_time': _selectedTime.format(context),
          'pickup_datetime': dt,
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride Updated!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Ride")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: "Destination"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(labelText: "Pickup Location"),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: Text("Pickup Time: ${_selectedTime.format(context)}"),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (t != null) setState(() => _selectedTime = t);
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _updateRide,
              child: const Text("SAVE CHANGES"),
            ),
          ],
        ),
      ),
    );
  }
}
