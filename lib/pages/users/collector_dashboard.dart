import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/pages/login_page.dart';

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

  static const Color greenColor = Color(0xFF1B6600);

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
            .collection('users') // your collection name
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
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCard({required Widget child, double height = 150}) {
    return Container(
      height: height,
      width: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 70;

    return Scaffold(
      backgroundColor: greenColor,
      appBar: AppBar(
        
        backgroundColor: greenColor,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white,),
        title: const Text(
          'COLLECTOR',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white,size: 28,),
            onPressed: () async => await _logout(context),
          ),]
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
                              color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
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
                      border: Border.all(color: Colors.white, width: 2),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,                 
                    children: [
                      const SizedBox(height: 10,),
                      // Customers List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          
                          _buildCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.group, color: greenColor, size: 60),
                                SizedBox(height: 10),
                                Text(
                                  'Customers List',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: greenColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30,),
                           _buildCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_box_outlined,
                                color: greenColor, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'Add Weight',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: greenColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                        ],
                      ),
                  
                      const SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.map_outlined,
                                    color: greenColor, size: 60),
                                SizedBox(height: 10),
                                Text(
                                  'Map',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: greenColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30,),
                           // Collection History
                      _buildCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.checklist_rounded,
                                color: greenColor, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'Collection History',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: greenColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                        ],
                      ),
                    const SizedBox(height: 20,),
                     
                  
                      // Collector Profile
                      Container(
                        height: 130,
                        width: double.infinity,
                        
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.settings_outlined,
                                  color: greenColor, size: 60),
                              SizedBox(height: 10),
                              Text(
                                'Collector Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: greenColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: greenColor,
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