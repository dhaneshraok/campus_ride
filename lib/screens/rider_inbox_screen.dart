import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class RiderInboxScreen extends StatelessWidget {
  const RiderInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Messages")),
      body: StreamBuilder<QuerySnapshot>(
        // Listen for chats where I AM THE RIDER
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('rider_uid', isEqualTo: myUid)
            .orderBy('last_message_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("No offers yet. Hang tight! 🦉"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFCC00), // Gold
                    child: Icon(Icons.person, color: Color(0xFF531017)),
                  ),
                  title: const Text(
                    "Driver Offered Help",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['last_message'] ?? "Start chatting...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Open the chat using the EXISTING ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          rideId: data['ride_id'],
                          riderUid: data['rider_uid'],
                          rideDestination: "My Ride", // Generic title for now
                          existingChatId:
                              chat.id, // <--- IMPORTANT: Pass the ID
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
