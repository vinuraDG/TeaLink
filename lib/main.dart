import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tealink/pages/login_page.dart';
import 'package:tealink/pages/onboarding_screen.dart';
import 'package:tealink/pages/option_page.dart';
import 'package:tealink/pages/user_registration_screen.dart';
import 'package:tealink/pages/users/customer_dashboard.dart';
 // Create this page if not already present

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        fontFamily: "Inter",
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => onboardingScreen(),
        '/register': (context) => UserRegistrationScreen(),
        '/signin': (context) => LoginPage(),
        '/option': (context) => RoleSelectionPage(),
        '/customerDashboard': (_) => CustomerDashboard(),
         // Define SignInScreen in your app
      },
    );
  }
}
