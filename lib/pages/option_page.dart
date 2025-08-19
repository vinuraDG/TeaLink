import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/pages/login_page.dart';
import 'package:TeaLink/pages/users/admin_dashboard.dart';
import 'package:TeaLink/pages/users/collector_dashboard.dart';
import 'package:TeaLink/pages/users/customer_dashboard.dart';
import 'package:TeaLink/widgets/session_manager.dart';

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

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  _RoleSelectionPageState createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  List<Map<String, dynamic>> collectors = [];
  String? selectedCollectorId;
  bool showCollectorDropdown = false;
  bool isLoadingCollectors = false;

  // Fetch available collectors from Firestore
  Future<void> fetchCollectors() async {
    setState(() {
      isLoadingCollectors = true;
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['Collector', 'collector', 'COLLECTOR'])
          .get();
      
      setState(() {
        collectors = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'registrationNumber': data['registrationNumber'] ?? '',
            'phone': data['phone'] ?? '',
          };
        }).toList();
        isLoadingCollectors = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCollectors = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load collectors: $e")),
      );
    }
  }

  // Create customer-collector connection
  Future<void> createCustomerCollectorConnection(String customerId, String collectorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('customer_collector_connections')
          .add({
        'customerId': customerId,
        'collectorId': collectorId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e) {
      throw Exception('Failed to create connection: $e');
    }
  }

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

    // If customer role is selected, show collector dropdown
    if (role.toLowerCase() == 'customer') {
      await fetchCollectors();
      setState(() {
        showCollectorDropdown = true;
      });
      return;
    }

    // For admin and collector roles, proceed directly
    await updateUserRole(context, role, uid);
  }

  Future<void> updateUserRole(BuildContext context, String role, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': role});
      await SessionManager.saveUserRole(role);

      if (role.toLowerCase() == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
      }
      if (role.toLowerCase() == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      }
      if (role.toLowerCase() == 'collector') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CollectorDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update role: $e")),
      );
    }
  }

  Future<void> completeCustomerRegistration() async {
    if (selectedCollectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a collector")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Update user role
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'Customer'});
      
      // Create customer-collector connection
      await createCustomerCollectorConnection(uid, selectedCollectorId!);
      
      await SessionManager.saveUserRole('Customer');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration completed successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to complete registration: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: kWhite),
        title: Row(
          children: [
            SizedBox(width: 65),
            Text(
              showCollectorDropdown ? "Select Collector" : "Select Role",
              style: TextStyle(
                color: kWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (showCollectorDropdown) {
              setState(() {
                showCollectorDropdown = false;
                selectedCollectorId = null;
              });
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
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
          child: showCollectorDropdown ? _buildCollectorSelection() : _buildRoleSelection(),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
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
    );
  }

  Widget _buildCollectorSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Select Your Collector',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose a collector from the list below:',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        if (isLoadingCollectors)
          const CircularProgressIndicator()
        else if (collectors.isEmpty)
          Column(
            children: [
              Icon(Icons.info, size: 50, color: Colors.orange),
              SizedBox(height: 10),
              Text(
                'No collectors available at the moment.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCollectorId,
                hint: const Text(
                  'Select a collector...',
                  style: TextStyle(color: Colors.grey),
                ),
                items: collectors.map((collector) {
                  return DropdownMenuItem<String>(
                    value: collector['id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collector['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (collector['registrationNumber'].isNotEmpty)
                          Text(
                            'Reg: ${collector['registrationNumber']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                       
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCollectorId = value;
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 30),
        if (collectors.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: selectedCollectorId != null ? Colors.green[700] : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: selectedCollectorId != null ? completeCustomerRegistration : null,
              child: const Text(
                'Complete Registration',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}