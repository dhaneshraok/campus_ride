import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'public_profile_screen.dart'; // Ensure this exists

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String riderUid;
  final String rideDestination;
  final String? existingChatId;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.riderUid,
    required this.rideDestination,
    this.existingChatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String currentUserId;
  late String chatId;

  bool isRideActive = true;
  String? otherUserUid;
  String? otherUserName;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Set Chat ID
    if (widget.existingChatId != null) {
      chatId = widget.existingChatId!;
    } else {
      chatId = "${widget.rideId}_$currentUserId";
    }

    _initChatRoom();
    _checkRideStatus();
    _loadOtherUserProfile();
  }

  // 1. Identify who we are talking to (for the Profile Link)
  Future<void> _loadOtherUserProfile() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      final driverUid = data['driver_uid'];
      final riderUid = data['rider_uid'];

      String targetUid;
      if (currentUserId == riderUid) {
        targetUid = driverUid; // If I am Rider, target is Driver
      } else {
        targetUid = riderUid; // If I am Driver, target is Rider
      }

      if (targetUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();
        if (mounted) {
          setState(() {
            otherUserUid = targetUid;
            if (userDoc.exists) {
              otherUserName = userDoc['full_name'];
            } else {
              otherUserName = "Ride Partner";
            }
          });
        }
      }
    }
  }

  void _checkRideStatus() {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              isRideActive = snapshot.data()?['status'] == 'OPEN';
            });
          }
        });
  }

  Future<void> _initChatRoom() async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      await chatDoc.set({
        'ride_id': widget.rideId,
        'rider_uid': widget.riderUid,
        'driver_uid': currentUserId,
        'started_at': FieldValue.serverTimestamp(),
        'last_message': 'Chat started',
        'last_message_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': messageText,
          'sender_id': currentUserId,
          'time': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'last_message': messageText,
      'last_message_time': FieldValue.serverTimestamp(),
    });

    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  // --- THE REVIEW LOGIC STARTS HERE ---

  // 2. The Logic to Update Status and Trigger Review
  Future<void> _updateRideStatus(String newStatus) async {
    // A. Update the database
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({'status': newStatus});

    // B. If COMPLETED, ask to Rate the Driver
    if (newStatus == 'COMPLETED') {
      if (!mounted) return;

      // We need the Driver's UID to save the review to the right profile
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      final driverUid = chatDoc['driver_uid'];

      if (driverUid != null) {
        _showRatingDialog(driverUid);
      } else {
        Navigator.pop(context); // Fallback exit
      }
    } else {
      Navigator.pop(context); // Exit if Cancelled
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride Cancelled")));
    }
  }

  // 3. The Actual Pop-up Box
  void _showRatingDialog(String driverUid) {
    final commentController = TextEditingController();
    double stars = 5;

    showDialog(
      context: context,
      barrierDismissible: false, // User must click Submit or Skip
      builder: (context) {
        return AlertDialog(
          title: const Text("Rate your Driver"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How was the ride?"),
                  const SizedBox(height: 10),
                  // Comment Box
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: "Great car, safe driver!",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  // Star Dropdown
                  DropdownButton<double>(
                    value: stars,
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.toDouble(),
                            child: Row(
                              children: [
                                Text("$e "),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => stars = val!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close Chat
              },
              child: const Text("Skip"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  // SAVE TO FIREBASE
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(driverUid)
                      .collection('reviews')
                      .add({
                        'stars': stars,
                        'comment': commentController.text,
                        'reviewer_uid': currentUserId,
                        'created_at': FieldValue.serverTimestamp(),
                      });

                  // OPTIONAL: Update Aggregate Stats (Sum/Count) on the User Doc here
                  // For now, we just save the review.
                }

                if (mounted) {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Close Chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review Submitted!")),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _viewProfile() {
    if (otherUserUid != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            userId: otherUserUid!,
            userName: otherUserName ?? "User Profile",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRider = currentUserId == widget.riderUid;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _viewProfile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    otherUserName ?? "Chat",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
              Text(
                isRideActive ? "Ride Active 🟢" : "Completed ⚫",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          // THE MENU BUTTON
          if (isRider && isRideActive)
            PopupMenuButton<String>(
              onSelected:
                  _updateRideStatus, // <--- Calls the logic we wrote above
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'COMPLETED',
                  child: Text('✅ Mark as Completed'),
                ),
                const PopupMenuItem(
                  value: 'CANCELLED',
                  child: Text('❌ Cancel Ride'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['sender_id'] == currentUserId;

                    // LABEL LOGIC
                    final bool isMessageFromRider =
                        msg['sender_id'] == widget.riderUid;
                    final String senderLabel = isMessageFromRider
                        ? "Rider"
                        : "Driver";

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            child: Text(
                              senderLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMessageFromRider
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFF531017),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe
                                    ? const Radius.circular(12)
                                    : const Radius.circular(0),
                                bottomRight: isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              msg['text'] ?? "",
                              style: TextStyle(
                                color: isMessageFromRider
                                    ? const Color(0xFF531017)
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFF531017),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
