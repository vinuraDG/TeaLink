import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/pages/users/collector_card/collector_customer_list.dart';
import 'package:TeaLink/widgets/dashboard_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/pages/login_page.dart';
// ✅ NEW PAGE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collector Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const CollectorDashboard(),
      debugShowCheckedModeBanner: false,
      routes: {
        // ✅ NEW ROUTE
        '/collector_customer_list': (context) => CollectorNotificationPage(
              collectorId: FirebaseAuth.instance.currentUser!.uid,
            ),
      },
    );
  }
}

class CollectorDashboard extends StatefulWidget {
  const CollectorDashboard({super.key});

  @override
  State<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard> {
  int _selectedIndex = 0;
  String userName = "";
  String greeting = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good Morning !";
    } else if (hour < 17) {
      greeting = "Good Afternoon !";
    } else {
      greeting = "Good Evening !";
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            userName = doc['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/collector_home'); // Already on home
      case 1:
        Navigator.pushNamed(context, '/collector_map');
        break;
      case 2:
        Navigator.pushNamed(context, '/collector_history');
        break;
      case 3:
        Navigator.pushNamed(context, '/collector_profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 70;

    return Scaffold(
      backgroundColor: kMainColor,
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: kWhite),
        title: const Text(
          'COLLECTOR',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhite),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: kWhite, size: 28),
            onPressed: () async => await _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header greeting row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  // Greetings
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $userName',
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: kWhite),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kWhite,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile avatar
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kWhite, width: 2),
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage('assets/images/avatar.jpg'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // White background container with cards
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: const BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Customers List + Add Weight
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DashboardCard(
                          title: "Customer List",
                          icon: Icons.list_alt,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/collector_customer_list',
                          ),
                        ),
                        const SizedBox(width: 20),
                        DashboardCard(
                          title: "Add Weight",
                          icon: Icons.add_circle_outline_rounded,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/collector_add_weight',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DashboardCard(
                          title: "Map",
                          icon: Icons.map_outlined,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/collector_map',
                          ),
                        ),
                        const SizedBox(width: 20),
                        DashboardCard(
                          title: "Collection History",
                          icon: Icons.history,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/collector_history',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DashboardCard(
                      title: "collector Profile",
                      icon: Icons.settings,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/collector_profile',
                      ),
                      isWide: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w900),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kMainColor,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Colors.grey[200],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_sharp),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
