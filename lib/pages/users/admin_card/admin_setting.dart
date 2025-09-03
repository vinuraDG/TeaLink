import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // You can use iconsax or material icons

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Settings"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // refresh logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // logout logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: const Text(
                  "Priyanjalee",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("priyanjaleebandara123@gmail.com\n0714491044"),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () {
                    // edit profile
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid of Settings
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSettingCard(
                  context,
                  Iconsax.people,
                  "Manage Users",
                  Colors.blue,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.tree,
                  "Harvest Data",
                  Colors.green,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.notification,
                  "Alerts",
                  Colors.orange,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.wallet_2,
                  "Payments",
                  Colors.purple,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.setting_2,
                  "System",
                  Colors.teal,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.security,
                  "Security",
                  Colors.red,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.chart,
                  "Reports",
                  Colors.indigo,
                  () {},
                ),
                _buildSettingCard(
                  context,
                  Iconsax.logout,
                  "Logout",
                  Colors.redAccent,
                  () {
                    // logout
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Settings tab active
        onTap: (index) {
          // navigate to pages
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: "Payment",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Setting",
          ),
        ],
      ),
    );
  }

  // Helper for grid items
  Widget _buildSettingCard(
      BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
