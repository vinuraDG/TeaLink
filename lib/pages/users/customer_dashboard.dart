import 'dart:io';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/widgets/dashboard_card.dart' hide kBlack;
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
        backgroundColor: kMainColor,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: kWhite, size: 28),
          backgroundColor: kMainColor,
          title: const Center(
            child: Text(
              "CUSTOMER",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhite),
            ),
          ),
          elevation: 0,
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
                                  color: kWhite, fontSize: 25, fontWeight: FontWeight.bold)),
                          Text(getGreeting(),
                              style: const TextStyle(
                                  color: kWhite, fontWeight: FontWeight.bold)),
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
                    color: kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            DashboardCard(
                              title: "Weekly Harvest",
                              subtitle: currentDate,
                              label: weeklyHarvest,
                            ),
                            SizedBox(width: 5,),
                            DashboardCard(
                              title: "Harvest Trends",
                              icon: Icons.insights,
                              onTap: () => Navigator.pushNamed(context, '/customer_trends'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            DashboardCard(
                              title: "Payment",
                              icon: Icons.payment,
                              onTap: () => Navigator.pushNamed(context, '/customer_payments'),
                            ),
                             SizedBox(width: 5,),
                            DashboardCard(
                              title: "Collector Info",
                              icon: Icons.person,
                              onTap: () => Navigator.pushNamed(context, '/customer_collector_info'),
                              disabled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DashboardCard(
                          title: "Customer Profile",
                          icon: Icons.settings,
                          onTap: () => Navigator.pushNamed(context, '/customer_profile'),
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
          backgroundColor: kBNavigationColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMainColor,
          unselectedItemColor: kBlack,
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
  }}