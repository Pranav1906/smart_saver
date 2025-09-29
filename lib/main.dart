import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'views/home_screen.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ads removed
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Saver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}