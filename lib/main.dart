import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Initializes Firebase in the app to use Firebase services
import 'package:firebase_auth/firebase_auth.dart'; // User authentication (login, signup, etc.)
import 'package:flutter_settings_screens/flutter_settings_screens.dart'; // Settings screen
import 'home.dart';
import 'login.dart';
import 'signup.dart';
import 'firebase_options.dart';

// Run the app
Future main() async {
  // Initialize Flutter before running asynchronous setup
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options (iOS, Android, Web, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize the flutter_settings_screens plugin
  await Settings.init();

  // Run the app after everything above has been initialized
  runApp(MyApp());
}

// Create the root widget (the first widget that gets shown)
// This is a stateless widget, meaning that the data does not change
class MyApp extends StatelessWidget {
  // Constructor (takes the properties of StatelessWidget)
  const MyApp({super.key});

  // Overwrite the build() method from the parent class (StatelessWidget)
  // Every widget that extends StatelessWidget must override the build() method
  // This method is what builds the app's UI
  @override
  Widget build(BuildContext context) {
    // MaterialApp is a widget that provides the structure for the app
    // This includes navigation between screens, consistent themes, etc.
    return MaterialApp(
      title: 'Private Twitter',
      // If the user is not logged in, show the login screen
      // Otherwise, show the home screen
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      // Define the screens that can be navigated to
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
      },
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}
