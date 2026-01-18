import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: const Color(0xFF531017),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER (Avatar + Rating Summary)
            Container(
              width: double.infinity,
              color: const Color(0xFF531017),
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  // Fetch User Stats for Stars/Car/Avatar
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      if (data == null)
                        return const Text(
                          "User info not found",
                          style: TextStyle(color: Colors.white70),
                        );

                      // Parse Data
                      int sum = data['rating_sum'] ?? 0;
                      int count = data['rating_count'] ?? 0;
                      double average = count > 0 ? sum / count : 0.0;
                      String car = data['car_model'] ?? "No Car Info";
                      String avatar = data['avatar'] ?? "🦉";

                      return Column(
                        children: [
                          // AVATAR DISPLAY
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 50),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // NAME
                          Text(
                            data['full_name'] ?? userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // RATING DISPLAY
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                average.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFCC00),
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFCC00),
                                size: 30,
                              ),
                              Text(
                                " ($count reviews)",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // CAR BADGE
                          if (data['is_driver'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    car,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // 2. REVIEWS LIST
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(16),
              child: const Text(
                "Recent Reviews",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF531017),
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('reviews')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final reviews = snapshot.data!.docs;

                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No reviews yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index].data() as Map<String, dynamic>;
                    final date =
                        (r['created_at'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            (r['stars'] ?? 0).toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(r['comment'] ?? ""),
                        subtitle: Text(DateFormat('MMM d, y').format(date)),
                        trailing: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
