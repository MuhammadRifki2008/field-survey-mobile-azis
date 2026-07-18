import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.assignment,
size: 100,
color: Colors.blue,
),
SizedBox(height: 20),
Text(
'Field Survey',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 10),
Text(
'Aplikasi Mobile Berbasis Flutter',
style: TextStyle(fontSize: 16),
),
],
),
),
);

  }
}