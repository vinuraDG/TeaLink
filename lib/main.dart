import 'package:TeaLink/pages/users/collector_card/add_weight.dart';
import 'package:TeaLink/pages/users/collector_card/collector_customer_list.dart';
import 'package:TeaLink/pages/users/collector_card/collector_profile.dart';
import 'package:TeaLink/pages/users/customer_cards/customer_profile.dart';
import 'package:TeaLink/pages/users/customer_cards/payment.dart';
import 'package:TeaLink/pages/users/customer_cards/trend.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TeaLink/pages/login_page.dart';
import 'package:TeaLink/pages/option_page.dart';
import 'package:TeaLink/pages/onboarding_screen.dart';
import 'package:TeaLink/pages/user_registration_screen.dart';
import 'package:TeaLink/pages/users/collector_dashboard.dart';
import 'package:TeaLink/pages/users/customer_dashboard.dart';
import 'package:TeaLink/widgets/session_manager.dart';

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
        '/customer_profile': (context) =>  ProfilePage(),
        '/customer_trends': (context) => TrendsPage(),
        '/customer_payments': (context) => PaymentsPage(),
        '/customer_home': (context) => CustomerDashboard(),

        '/collectorDashboard': (context) => CollectorDashboard(),
        '/collector_customer_list': (context) =>  CollectorCustomerListPage(collectorId: '',),
        '/collector_add_weight': (context) => AddWeightPage(),
        '/collector_map': (context) => PaymentsPage(),
        '/collector_history': (context) => CustomerDashboard(),
         '/collector_profile': (context) =>  CollectorProfile(),
         '/collector_home': (context) => CollectorDashboard(),
        

      },
    );
  }
}
