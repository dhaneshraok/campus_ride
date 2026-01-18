import 'package:campus_ride/screens/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For Web check
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/role_selection_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
// Make sure this matches your file path.
// If your file is in lib/screens/create_ride_screen.dart, this is correct.
import 'screens/create_ride_screen.dart';

// --- 1. THE MAIN ENTRY POINT (This was missing) ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
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

  // 2. SETUP NOTIFICATIONS
  // Request permission (Apple/Web requires this)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Get the unique Token (The address of THIS device)
  String? token = await messaging.getToken(
    vapidKey:
        "BGWYWsEWiZeZBUaocOr1FWZb_TnH3aDJsmbDbc05FYD4pnqFxHiGrg_6OemWdr3E60lgYCquShpdQvFck-Y1GYQ",
    // ^ Web needs a key, Android doesn't. We'll leave it blank for now to test Android,
    // or generate one for Web.
  );
  print("🔥 MY DEVICE TOKEN: $token");

  // Listen for messages while app is open
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  // 3. Auto-Login (Your existing code)
  // try {
  //   await FirebaseAuth.instance.signInAnonymously();
  // } catch (e) {
  //   print(e);
  // }

  runApp(const MyApp());
}

// --- 2. THE APP CONFIGURATION (Your new Theme) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rowan Rides',
      debugShowCheckedModeBanner: false,

      // THE ROWAN THEME
      theme: ThemeData(
        useMaterial3: true,
        // Rowan Brown Primary
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF531017), // Rowan Maroon/Brown
          primary: const Color(0xFF531017),
          secondary: const Color(0xFFFFCC00), // Rowan Gold
        ),

        // Better Text Styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF531017),
          foregroundColor: Colors.white, // White text on Brown header
          elevation: 0,
        ),

        // Styled Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFCC00), // Gold Buttons
            foregroundColor: const Color(0xFF531017), // Brown Text
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Background Color (Light Grey is cleaner than pure white)
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),

      home: const AuthWrapper(),
    );
  }
}

// This Widget decides where to send the user
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 1)); // Splash delay

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // NO USER -> GO TO LOGIN
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // USER EXISTS -> CHECK PROFILE
      _checkProfile(user.uid);
    }
  }

  Future<void> _checkProfile(String uid) async {
    // 2. Check Firestore for profile
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (mounted) {
      if (doc.exists) {
        // Has profile -> Go to Menu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      } else {
        // No profile -> Go to Setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
