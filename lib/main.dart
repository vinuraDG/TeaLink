import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:TeaLink/pages/users/admin_card/admin_payment.dart';
import 'package:TeaLink/pages/users/admin_card/admin_setting.dart';
import 'package:TeaLink/pages/users/admin_card/manage_users.dart';
import 'package:TeaLink/pages/users/admin_dashboard.dart';
import 'package:TeaLink/pages/users/collector_card/collection_history.dart';
import 'package:TeaLink/pages/users/collector_card/collector_customer_list.dart';
import 'package:TeaLink/pages/users/collector_card/collector_map.dart';
import 'package:TeaLink/pages/users/collector_card/collector_profile.dart';
import 'package:TeaLink/pages/users/customer_cards/collector_info.dart';
import 'package:TeaLink/pages/users/customer_cards/customer_profile.dart';
import 'package:TeaLink/pages/users/customer_cards/customer_payment.dart';
import 'package:TeaLink/pages/users/customer_cards/trend.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TeaLink/pages/login_page.dart';
import 'package:TeaLink/pages/option_page.dart';
import 'package:TeaLink/pages/onboarding_screen.dart'; // Make sure this imports the correct OnboardingScreen class
import 'package:TeaLink/pages/user_registration_screen.dart';
import 'package:TeaLink/pages/users/collector_dashboard.dart';
import 'package:TeaLink/pages/users/customer_dashboard.dart';
import 'package:TeaLink/pages/language_selection_page.dart';
import 'package:TeaLink/widgets/session_manager.dart';
import 'package:TeaLink/services/language_service.dart';
import 'package:TeaLink/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize language provider first
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();
  
  String initialRoute = await getInitialRoute();
  
  runApp(MyApp(
    initialRoute: initialRoute,
    languageProvider: languageProvider,
  ));
}

Future<String> getInitialRoute() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  
  // Check if language has been set before
  bool languageSet = await LanguageService.isLanguageSet();
  if (!languageSet) {
    return '/language'; // First time - show language selection
  }

  if (user == null) return '/'; // Onboarding for first-time visitors

  String? role = await SessionManager.getUserRole();
  if (role?.toLowerCase() == 'customer') return '/customerDashboard';
  if (role?.toLowerCase() == 'collector') return '/collectorDashboard';
  if (role?.toLowerCase() == 'admin') return '/Admin';
  return '/option';
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final LanguageProvider languageProvider;
  
  const MyApp({
    super.key, 
    required this.initialRoute,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageProvider>.value(
      value: languageProvider,
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: "TeaLink",
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: "Inter"),
            
            // Localization configuration
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.getSupportedLocales(),
            locale: languageProvider.currentLocale,
            
            // Locale resolution callback to handle unsupported locales
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              // Return current provider locale or fallback to English
              return languageProvider.currentLocale;
            },
            
            initialRoute: initialRoute,
            routes: {
              '/language': (context) => const LanguageSelectionPage(isFirstTime: true),
              '/language-settings': (context) => const LanguageSelectionPage(isFirstTime: false),
              '/': (context) => const OnboardingScreen(), // Fixed: Use proper class name and const
              
              '/register': (context) => const UserRegistrationScreen(), // Added const
              '/signin': (context) => const LoginPage(), // Added const
              '/option': (context) => const RoleSelectionPage(), // Added const

              '/Admin': (context) => AdminDashboard(), // Added const
              '/admin_home': (context) => AdminDashboard(),
              '/admin_payment_slip': (context) => AdminPaymentSlipPage(),
              '/admin_users': (context) => ManageUsersPage(),
              '/admin_settings': (context) => const AdminSettingsPage(),

              '/customerDashboard': (context) => const CustomerDashboard(),
              '/customer_profile': (context) => const ProfilePage(),
              '/customer_trends': (context) => const HarvestTrendsPage(),
              '/customer_payments': (context) => const CustomerPaymentSlipPage(),
              '/customer_home': (context) => const CustomerDashboard(),
              '/customer_collector_info': (context) => const CollectorInfoPage(
                collectorId: 'tKFNK70gH2SYUvwFo5gEmVg5JFB3',
              ),

              '/collectorDashboard': (context) => const CollectorDashboard(),                           
              '/collector_map': (context) => const CollectorMapPage(),
              '/collector_history': (context) => CollectionHistoryPage(
                collectorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              '/collector_profile': (context) => const CollectorProfile(),
              '/collector_home': (context) => const CollectorDashboard(),
              '/collector_customer_list': (context) => CollectorNotificationPage(
                collectorId: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
            },
          );
        },
      ),
    );
  }
}