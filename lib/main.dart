import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDpZI0Rawx3mgdQNWbmCXuvmALkLe4Oljk",
        authDomain: "assignment21-19f46.firebaseapp.com",
        databaseURL:
            "https://assignment21-19f46-default-rtdb.asia-southeast1.firebasedatabase.app/",
        projectId: "assignment21-19f46",
        storageBucket: "assignment21-19f46.appspot.com",
        messagingSenderId: "28781935793",
        appId: "1:28781935793:android:1c8df195694145fa96f690",
      ),
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
