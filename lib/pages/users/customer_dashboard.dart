import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tealink/pages/login_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName;
  String currentDate = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    formatDate();
  }

  void formatDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd\nEEEE').format(now);
    setState(() {
      currentDate = formattedDate;
    });
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        displayName = doc.data()?['name'] ?? 'User';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _logout(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.green[700],
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: const Text(
            "CUSTOMER",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async => await _logout(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, ${displayName ?? '...'}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(getGreeting(),
                              style: const TextStyle(
                                  color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/avatar.jpg'),
                    ),
                  ],
                ),
              ),

              // White Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dashboardCard(
                              title: "Weekly Harvest",
                              subtitle: currentDate,
                              icon: Icons.scale,
                              label: "50kg",
                            ),
                            const SizedBox(width: 20),
                            _dashboardCard(
                              title: "Harvest Trends",
                              icon: Icons.insights,
                              onTap: () => Navigator.pushNamed(context, '/trends'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Bottom Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dashboardCard(
                              title: "Payment",
                              icon: Icons.payment,
                              onTap: () => Navigator.pushNamed(context, '/payments'),
                            ),
                            const SizedBox(width: 20),
                            _dashboardCard(
                              title: "Collector Info",
                              icon: Icons.person,
                              onTap: () => Navigator.pushNamed(context, '/collector'),
                              disabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Profile Section
                        _dashboardCard(
                          title: "Customer Profile",
                          icon: Icons.settings,
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          isWide: true,
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
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        
        
        elevation: 0,
        
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _dashboardCard({
    required String title,
    IconData? icon,
    String? subtitle,
    String? label,
    bool disabled = false,
    bool isWide = false,
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: isWide ? double.infinity : 160,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[200] : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null)
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (icon != null) Icon(icon, color: Colors.green, size: 28),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: card,
    );
  }
}
