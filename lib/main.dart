import 'package:flutter/material.dart';
// import 'package:field_survey/screens/splash/splash_screen.dart';
import 'package:field_survey/routes/app_pages.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppPages.router,
    );
  }
}
