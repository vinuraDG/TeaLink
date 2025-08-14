import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:TeaLink/pages/login_page.dart';

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

  File? _profileImage;
  String weeklyHarvest = '...';

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchWeeklyHarvest();
    formatDate();
    _loadProfileImage();
  }

  void formatDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd\nEEEE').format(now);
    setState(() => currentDate = formattedDate);
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() => displayName = doc.data()?['name'] ?? 'User');
    }
  }

  Future<void> fetchWeeklyHarvest() async {
    if (user != null) {
      try {
        final harvestDoc = await FirebaseFirestore.instance
            .collection('harvest')
            .doc(user!.uid)
            .get();
        setState(() {
          weeklyHarvest = "${harvestDoc.data()?['weeklyAmount'] ?? 0}kg";
        });
      } catch (e) {
        setState(() => weeklyHarvest = '0kg');
      }
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image.png';
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        setState(() => _profileImage = imageFile);
      }
    } catch (_) {}
  }

  Future<void> _pickAndSaveImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final savedImage = File('${directory.path}/profile_image.png');
      await File(pickedFile.path).copy(savedImage.path);

      setState(() => _profileImage = savedImage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image update failed: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
  setState(() => _selectedIndex = index);

  switch (index) {
    case 0:
      Navigator.pushNamed(context, '/home');// Already on home
    case 1:
      Navigator.pushNamed(context, '/trends');
      break;
    case 2:
      Navigator.pushNamed(context, '/payments');
      break;
    case 3:
      Navigator.pushNamed(context, '/profile'); // Profile page route
      break;
  }
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
          iconTheme: const IconThemeData(color: Colors.white, size: 28),
          backgroundColor: Colors.green[700],
          title: const Center(
            child: Text(
              "CUSTOMER",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 28),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, ${displayName ?? '...'}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                          Text(getGreeting(),
                              style: const TextStyle(
                                  color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickAndSaveImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                      ),
                    ),
                  ],
                ),
              ),

              // White content container
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dashboardCard(
                              title: "Weekly Harvest",
                              subtitle: currentDate,
                              label: weeklyHarvest,
                            ),
                            SizedBox(width: 20,),
                            _dashboardCard(
                              title: "Harvest Trends",
                              icon: Icons.insights,
                              onTap: () => Navigator.pushNamed(context, '/trends'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dashboardCard(
                              title: "Payment",
                              icon: Icons.payment,
                              onTap: () => Navigator.pushNamed(context, '/payments'),
                            ),
                             SizedBox(width: 20,),
                            _dashboardCard(
                              title: "Collector Info",
                              icon: Icons.person,
                              onTap: () => Navigator.pushNamed(context, '/collector'),
                              disabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
          backgroundColor: Colors.grey[200],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.black,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_sharp), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_sharp), label: 'Trends'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
      width: isWide ? double.infinity : 165,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2.0),
        color: disabled ? Colors.grey[200] : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null)
            Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          if (icon != null) Icon(icon, color: Colors.green, size: 60),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Text(subtitle, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );

    return GestureDetector(onTap: disabled ? null : onTap, child: card);
  }
}
