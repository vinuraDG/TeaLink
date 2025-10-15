import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/pages/login_page.dart';
import 'package:TeaLink/pages/users/admin_dashboard.dart';
import 'package:TeaLink/pages/users/collector_dashboard.dart';
import 'package:TeaLink/pages/users/customer_dashboard.dart';
import 'package:TeaLink/l10n/app_localizations.dart'; // import localization

class RoleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const RoleButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: kWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 20,
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  _RoleSelectionPageState createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> collectors = [];
  String? selectedCollectorId;
  bool showCollectorDropdown = false;
  bool isLoadingCollectors = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fetch collectors from Firestore
  Future<void> fetchCollectors() async {
    setState(() {
      isLoadingCollectors = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Collector')
          .get();

      setState(() {
        collectors = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data().toString().contains('name') ? doc['name'] : 'Unknown Collector',
            'email': doc.data().toString().contains('email') ? doc['email'] : '',
          };
        }).toList();
        isLoadingCollectors = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCollectors = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching collectors: $e')),
      );
    }
  }

  // Navigate to role-specific pages
  void navigateToRolePage(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (role == 'Customer') {
        await fetchCollectors();
        setState(() {
          showCollectorDropdown = true;
        });
        _animationController.reset();
        _animationController.forward();
      } else {
        // Update user role in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': role});

        // Navigate to appropriate dashboard
        Widget targetPage;
        switch (role) {
          case 'Admin':
            targetPage =  AdminDashboard();
            break;
          case 'Collector':
            targetPage = const CollectorDashboard();
            break;
          default:
            targetPage = const CustomerDashboard();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    }
  }

  // Complete customer registration with collector selection
  Future<void> completeCustomerRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedCollectorId == null) return;

    try {
      // Update user role and assign collector
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': 'Customer',
        'assignedCollector': selectedCollectorId,
      });

      // Create connection between customer and collector
      await createCustomerCollectorConnection(user.uid, selectedCollectorId!);

      // Navigate to customer dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomerDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing registration: $e')),
      );
    }
  }

  // Create connection between customer and collector
  Future<void> createCustomerCollectorConnection(String customerId, String collectorId) async {
    try {
      await FirebaseFirestore.instance.collection('connections').add({
        'customerId': customerId,
        'collectorId': collectorId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e) {
      print('Error creating connection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // localization instance

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (showCollectorDropdown) {
              setState(() {
                showCollectorDropdown = false;
                selectedCollectorId = null;
              });
              _animationController.reset();
              _animationController.forward();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
        ),
        title: Text(
          showCollectorDropdown
              ? loc.selectCollector // localized
              : loc.chooseRole, // localized
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: showCollectorDropdown
                ? _buildCollectorSelection(loc)
                : _buildRoleSelection(loc),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(AppLocalizations loc) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          loc.welcome, // localized welcome
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.selectRoleSubtitle, // localized subtitle
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 40),
        RoleButton(
          label: loc.adminRole,
          subtitle: loc.adminSubtitle,
          icon: Icons.admin_panel_settings,
          color: Colors.purple[600]!,
          onPressed: () => navigateToRolePage(context, 'Admin'),
        ),
        RoleButton(
          label: loc.customerRole,
          subtitle: loc.customerSubtitle,
          icon: Icons.person,
          color: Colors.blue[600]!,
          onPressed: () => navigateToRolePage(context, 'Customer'),
        ),
        RoleButton(
          label: loc.collectorRole,
          subtitle: loc.collectorSubtitle,
          icon: Icons.local_shipping,
          color: Colors.green[600]!,
          onPressed: () => navigateToRolePage(context, 'Collector'),
        ),
      ],
    );
  }

  Widget _buildCollectorSelection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.collectorInfo, // localized info text
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (isLoadingCollectors)
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.green[600]),
                const SizedBox(height: 20),
                Text(loc.loadingCollectors),
              ],
            ),
          )
        else if (collectors.isEmpty)
          Center(
            child: Text(
              loc.noCollectors,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
          )
        else ...[
          Text(
            '${loc.availableCollectors} (${collectors.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(loc.selectCollector),
                value: selectedCollectorId,
                items: collectors.map((collector) {
                  return DropdownMenuItem<String>(
                    value: collector['id'],
                    child: Text(collector['name']),
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  selectedCollectorId != null ? completeCustomerRegistration : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCollectorId != null
                    ? Colors.green[600]
                    : Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                loc.completeRegistration, // localized button
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}