import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/notification_provider.dart';

/// Handle background FCM messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDcIDYfuVZhfDejakXMu0YacHXWjBBMvkk",
        authDomain: "campusride-965c9.firebaseapp.com",
        projectId: "campusride-965c9",
        storageBucket: "campusride-965c9.firebasestorage.app",
        messagingSenderId: "178371494392",
        appId: "1:178371494392:web:c009bae540730a0f53560d",
        measurementId: "G-NJEM902CRV",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Set up FCM
  try {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages — show as in-app snackbar via navigatorKey
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM: ${message.notification?.title}');
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tap: ${message.data}');
    });
  } catch (e) {
    debugPrint('Notification setup error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => RideProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const CampusRideApp(),
    ),
  );
}
