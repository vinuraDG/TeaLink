import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tealink/constants/colors.dart';
import 'package:tealink/pages/login_page.dart';
import 'package:tealink/pages/users/customer_dashboard.dart';
import 'package:tealink/widgets/session_manager.dart'; // ✅ Import your login page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const RoleButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role Selection',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: RoleSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void navigateToRolePage(BuildContext context, String role) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final doc = await docRef.get();

  if (doc.exists && doc.data()?['role'] != null && doc['role'] != '') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You already registered as ${doc['role']}. Cannot change role.")),
    );
    return;
  }

  await docRef.update({'role': role});
  await SessionManager.saveUserRole(role);

  if (role.toLowerCase() == 'customer') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CustomerDashboard()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        iconTheme: IconThemeData(color: kWhite),// ✅ AppBar with back button
        title: Row(
          children: [
            SizedBox(width: 65),
            Text("Select Role",style: TextStyle(color: kWhite,fontSize: 24, fontWeight: FontWeight.bold, ),),
          ],
        ),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // ✅ Navigate to Login Page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoleButton(
                label: 'ADMIN',
                onPressed: () => navigateToRolePage(context, 'Admin'),
              ),
              const SizedBox(height: 20),
              RoleButton(
                label: 'CUSTOMER',
                onPressed: () => navigateToRolePage(context, 'Customer'),
              ),
              const SizedBox(height: 20),
              RoleButton(
                label: 'COLLECTOR',
                onPressed: () => navigateToRolePage(context, 'Collector'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}