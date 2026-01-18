import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. GET MY ID
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Rides"),
        backgroundColor: const Color(0xFF531017),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'OPEN')
            .where('pickup_datetime', isGreaterThan: DateTime.now())
            .orderBy('pickup_datetime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final rides = snapshot.data!.docs;

          // 2. FILTER OUT MY OWN RIDES MANUALLY
          // We create a new list that excludes any ride where rider_uid == me
          final otherPeoplesRides = rides.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['rider_uid'] != myUid;
          }).toList();

          if (otherPeoplesRides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text("No new requests from others."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: otherPeoplesRides.length,
            itemBuilder: (context, index) {
              final ride = otherPeoplesRides[index];
              final data = ride.data() as Map<String, dynamic>;

              final bool isUrgent = data['is_urgent'] ?? false;
              final String riderName = data['rider_name'] ?? "Student";
              final String riderAvatar = data['rider_avatar'] ?? "🦉";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isUrgent
                      ? const BorderSide(color: Colors.red, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(
                              riderAvatar,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              riderName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF531017),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red[100]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['pickup_time'] is String
                                  ? data['pickup_time']
                                  : "Scheduled",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isUrgent ? Colors.red : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // ROUTE DETAILS
                      _buildRow(
                        Icons.location_on,
                        "To: ${data['destination']}",
                        true,
                      ),
                      const SizedBox(height: 8),
                      _buildRow(
                        Icons.map,
                        "Pickup: ${data['pickup_area']}",
                        false,
                      ),

                      const SizedBox(height: 15),

                      // ACTION BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  rideId: ride.id,
                                  riderUid: data['rider_uid'],
                                  rideDestination: data['destination'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            foregroundColor: const Color(0xFF531017),
                          ),
                          child: const Text(
                            "OFFER TO HELP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRow(IconData icon, String text, bool isBold) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
