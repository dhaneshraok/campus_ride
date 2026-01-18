import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_ride_screen.dart';
import 'driver_home_screen.dart';
import 'rider_inbox_screen.dart';
import 'ride_history_screen.dart';
import 'edit_profile_screen.dart';
import '../main.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String userName = "Student";
  String userEmail = "";
  String userAvatar = "🦉"; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            userEmail = user.email ?? "";
            if (doc.exists) {
              // --- THE FIX IS HERE ---
              // We cast the data to a Map so we can check if keys exist safely
              final data = doc.data() as Map<String, dynamic>;

              userName = data['full_name'] ?? "Student";

              // If 'avatar' exists, use it. If not, use '🦉'
              if (data.containsKey('avatar')) {
                userAvatar = data['avatar'];
              } else {
                userAvatar = "🦉";
              }
            }
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rowan Rides"),
        elevation: 0,
        backgroundColor: const Color(0xFF531017),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFFFFCC00),
                child: Text(userAvatar, style: const TextStyle(fontSize: 40)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF531017)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  _loadUserData();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Ride History"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF531017),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Color(0xFFFFCC00)),
            const SizedBox(height: 20),
            const Text(
              "Where to today?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),

            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRideScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF531017),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text("I NEED A RIDE"),
                  ],
                ),
              ),
            ),

            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderInboxScreen()),
                );
              },
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text(
                "Check My Messages",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.drive_eta),
                    SizedBox(width: 10),
                    Text("I AM A DRIVER"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
