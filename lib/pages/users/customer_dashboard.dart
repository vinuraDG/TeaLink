import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerDashboard extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

   CustomerDashboard({super.key});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: SafeArea(
        child: Column(
          children: [
            // Top Greeting Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CUSTOMER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text("Hello, ${user?.displayName ?? 'Vinura'}", style: const TextStyle(color: Colors.white, fontSize: 22)),
                        Text(getGreeting(), style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/user_avatar.png'), // Replace with your asset
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
                child: Column(
                  children: [
                    // Top Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dashboardCard(
                          title: "Weekly Harvest",
                          subtitle: "2025/05/26\nMonday",
                          icon: Icons.scale,
                          label: "50kg",
                        ),
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Trends"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
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
      width: isWide ? double.infinity : 150,
      height: 120,
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
          if (subtitle != null) Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: card,
    );
  }
}
