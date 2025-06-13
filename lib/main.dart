import 'package:flutter/material.dart';
import 'package:tealink/pages/onboarding_screen.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TeaLink",
      theme: ThemeData(
        fontFamily: "Inter" ),
      home: onboardingScreen(),
    );
  }
}