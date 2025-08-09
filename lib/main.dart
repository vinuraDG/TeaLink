import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tealink/pages/login_page.dart';
import 'package:tealink/pages/option_page.dart';
import 'package:tealink/pages/onboarding_screen.dart';
import 'package:tealink/pages/user_registration_screen.dart';
import 'package:tealink/pages/users/customer_dashboard.dart';
import 'package:tealink/widgets/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  String initialRoute = await getInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  if (user == null) return '/'; // Onboarding for first-time visitors

  String? role = await SessionManager.getUserRole();
  if (role != null) {
    if (role.toLowerCase() == 'customer') return '/customerDashboard';
    // Extend for Admin/Collector later
  }
  return '/option';
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TeaLink",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Inter"),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => onboardingScreen(),
        '/register': (context) => UserRegistrationScreen(),
        '/signin': (context) => LoginPage(),
        '/option': (context) => RoleSelectionPage(),
        '/customerDashboard': (context) => CustomerDashboard(),
      },
    );
  }
}
