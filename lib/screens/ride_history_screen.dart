import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_ride_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Ride History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('rider_uid', isEqualTo: myUid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final rides = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'OPEN';

              // SAFETY CHECK: Handle pickup_time carefully
              String timeDisplay = "Time not set";
              if (data['pickup_time'] is String) {
                timeDisplay = data['pickup_time'];
              } else if (data['pickup_time'] is Timestamp) {
                // If it accidentally got saved as a Timestamp, handle it
                timeDisplay = "Scheduled";
              }

              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.directions_car,
                        color: status == 'OPEN' ? Colors.blue : Colors.grey,
                      ),
                      title: Text(data['destination'] ?? "Unknown Destination"),
                      subtitle: Text("Status: $status"),
                      trailing: Text(timeDisplay), // <--- Uses the safe string
                    ),

                    if (status == 'OPEN')
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Edit Details"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditRideScreen(
                                      rideId: ride.id,
                                      currentData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
