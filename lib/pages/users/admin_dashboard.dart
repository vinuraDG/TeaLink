// admin_dashboard.dart
import 'package:TeaLink/pages/users/admin_card/alert.dart';
import 'package:TeaLink/pages/users/admin_card/manage_users.dart';
import 'package:TeaLink/pages/users/admin_card/view_harvest.dart';
import 'package:TeaLink/pages/users/customer_cards/payment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Statistics (totalUsers now excludes admins)
  int totalUsers = 0; // Only customers + collectors
  int totalCustomers = 0;
  int totalCollectors = 0;
  int totalHarvests = 0;
  int totalPayments = 0;
  int todayUsers = 0; // Only customers + collectors registered today
  int todayHarvests = 0;
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _harvestsSubscription;
  StreamSubscription<QuerySnapshot>? _paymentsSubscription;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeData();
  }

  @override
  void dispose() {
    // Cancel all subscriptions and timers
    _usersSubscription?.cancel();
    _harvestsSubscription?.cancel();
    _paymentsSubscription?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  void _initializeRealTimeData() {
    setState(() {
      isLoading = true;
    });
    
    _setupRealTimeListeners();
    _checkForAlerts();
    
    // Setup periodic alert checking (every 5 minutes)
    _alertTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkForAlerts();
    });
    
    setState(() {
      isLoading = false;
    });
  }

  void _setupRealTimeListeners() {
    // Load manually first, then set up real-time listeners
    _loadStatisticsManually().then((_) {
      // Check if user is admin before setting up listeners
      _checkAdminStatus().then((isAdminUser) {
        if (!isAdminUser) {
          print('User is not admin, using manual data loading only');
          return;
        }

        // Real-time listener for users collection (only if admin)
        _usersSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
          if (mounted) {
            _updateUserStatistics(snapshot);
          }
        }, onError: (e) {
          print('Error listening to users: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Real-time updates disabled. Using manual refresh.')),
            );
          }
        });

        // Real-time listener for harvest_value collection
        _harvestsSubscription = _firestore.collection('harvest_value').snapshots().listen((snapshot) {
          if (mounted) {
            _updateHarvestStatistics(snapshot);
          }
        }, onError: (e) {
          print('Error listening to harvests: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Harvest updates disabled. Using manual refresh.')),
            );
          }
        });

        // Real-time listener for payments collection
        _paymentsSubscription = _firestore.collection('payments').snapshots().listen((snapshot) {
          if (mounted) {
            setState(() {
              totalPayments = snapshot.docs.length;
            });
          }
        }, onError: (e) {
          print('Error listening to payments: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment updates disabled. Using manual refresh.')),
            );
          }
        });
      });
    });
  }

  Future<bool> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role']?.toString().toLowerCase() ?? '';
      return role == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> _loadStatisticsManually() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final harvestsSnapshot = await _firestore.collection('harvest_value').get();
      final paymentsSnapshot = await _firestore.collection('payments').get();
      
      int customers = 0;
      int collectors = 0;
      int usersToday = 0;
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role']?.toString().toLowerCase() ?? '';
        
        // Only count customers and collectors, exclude admin
        if (role == 'customer') {
          customers++;
          
          // Check if customer registered today
          final createdAt = data['createdAt'];
          if (createdAt != null) {
            DateTime userCreatedDate;
            if (createdAt is Timestamp) {
              userCreatedDate = createdAt.toDate();
            } else if (createdAt is String) {
              userCreatedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
            } else {
              userCreatedDate = DateTime.now();
            }
            
            if (userCreatedDate.isAfter(startOfDay)) {
              usersToday++;
            }
          }
        } else if (role == 'collector') {
          collectors++;
          
          // Check if collector registered today
          final createdAt = data['createdAt'];
          if (createdAt != null) {
            DateTime userCreatedDate;
            if (createdAt is Timestamp) {
              userCreatedDate = createdAt.toDate();
            } else if (createdAt is String) {
              userCreatedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
            } else {
              userCreatedDate = DateTime.now();
            }
            
            if (userCreatedDate.isAfter(startOfDay)) {
              usersToday++;
            }
          }
        }
        // Skip admin users - they are not counted in totalUsers
      }

      // Update harvest statistics
      int harvestsToday = 0;
      for (var doc in harvestsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt != null) {
          final harvestDate = createdAt.toDate();
          if (harvestDate.isAfter(startOfDay)) {
            harvestsToday++;
          }
        }
      }

      if (mounted) {
        setState(() {
          // totalUsers now only includes customers + collectors
          totalUsers = customers + collectors;
          totalCustomers = customers;
          totalCollectors = collectors;
          todayUsers = usersToday; // Only new customers + collectors today
          totalHarvests = harvestsSnapshot.docs.length;
          todayHarvests = harvestsToday;
          totalPayments = paymentsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading statistics manually: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  Future<void> _loadHarvestStatisticsManually() async {
    try {
      final harvestsSnapshot = await _firestore.collection('harvest_value').get();
      int harvestsToday = 0;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      for (var doc in harvestsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt != null) {
          final harvestDate = createdAt.toDate();
          if (harvestDate.isAfter(startOfDay)) {
            harvestsToday++;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalHarvests = harvestsSnapshot.docs.length;
          todayHarvests = harvestsToday;
        });
      }
    } catch (e) {
      print('Error loading harvest statistics: $e');
    }
  }

  Future<void> _loadPaymentStatisticsManually() async {
    try {
      final paymentsSnapshot = await _firestore.collection('payments').get();
      if (mounted) {
        setState(() {
          totalPayments = paymentsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading payment statistics: $e');
    }
  }

  void _updateUserStatistics(QuerySnapshot snapshot) {
    int customers = 0;
    int collectors = 0;
    int usersToday = 0;
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role']?.toString().toLowerCase() ?? '';
      
      // Only count customers and collectors, exclude admin
      if (role == 'customer') {
        customers++;
        
        // Check if customer registered today
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime userCreatedDate;
          if (createdAt is Timestamp) {
            userCreatedDate = createdAt.toDate();
          } else if (createdAt is String) {
            userCreatedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
          } else {
            userCreatedDate = DateTime.now();
          }
          
          if (userCreatedDate.isAfter(startOfDay)) {
            usersToday++;
          }
        }
      } else if (role == 'collector') {
        collectors++;
        
        // Check if collector registered today
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime userCreatedDate;
          if (createdAt is Timestamp) {
            userCreatedDate = createdAt.toDate();
          } else if (createdAt is String) {
            userCreatedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
          } else {
            userCreatedDate = DateTime.now();
          }
          
          if (userCreatedDate.isAfter(startOfDay)) {
            usersToday++;
          }
        }
      }
      // Skip admin users - they are not counted
    }

    setState(() {
      // totalUsers now only includes customers + collectors
      totalUsers = customers + collectors;
      totalCustomers = customers;
      totalCollectors = collectors;
      todayUsers = usersToday; // Only new customers + collectors today
    });
  }

  void _updateHarvestStatistics(QuerySnapshot snapshot) {
    int harvestsToday = 0;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;
      
      if (createdAt != null) {
        final harvestDate = createdAt.toDate();
        if (harvestDate.isAfter(startOfDay)) {
          harvestsToday++;
        }
      }
    }

    setState(() {
      totalHarvests = snapshot.docs.length;
      todayHarvests = harvestsToday;
    });
  }

  Future<void> _checkForAlerts() async {
    try {
      final harvestsSnapshot = await _firestore.collection('harvest_value').get();
      List<Map<String, dynamic>> newAlerts = [];
      
      // Group harvests by date and customer
      Map<String, Map<String, List<DocumentSnapshot>>> harvestsByDateAndCustomer = {};
      
      for (var doc in harvestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['createdAt'] as Timestamp?;
        final customerRegNo = data['customerRegNo']?.toString() ?? 'Unknown';
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month}-${date.day}';
          
          harvestsByDateAndCustomer[dateKey] ??= {};
          harvestsByDateAndCustomer[dateKey]![customerRegNo] ??= [];
          harvestsByDateAndCustomer[dateKey]![customerRegNo]!.add(doc);
        }
      }
      
      // Check for duplicate weights on same day
      harvestsByDateAndCustomer.forEach((date, customerMap) {
        customerMap.forEach((customer, harvests) {
          if (harvests.length > 1) {
            // Multiple entries for same customer on same day
            final weights = harvests.map((h) => (h.data() as Map<String, dynamic>)['weight']?.toString() ?? '0').toList();
            newAlerts.add({
              'type': 'duplicate_entries',
              'title': 'Multiple Entries Detected',
              'description': 'Customer $customer has ${harvests.length} entries on $date',
              'severity': 'high',
              'date': date,
              'customer': customer,
              'weights': weights,
            });
          }
          
          // Check for duplicate weights
          Map<String, int> weightCount = {};
          for (var harvest in harvests) {
            final weight = (harvest.data() as Map<String, dynamic>)['weight']?.toString() ?? '0';
            weightCount[weight] = (weightCount[weight] ?? 0) + 1;
          }
          
          weightCount.forEach((weight, count) {
            if (count > 1) {
              newAlerts.add({
                'type': 'duplicate_weight',
                'title': 'Duplicate Weight Alert',
                'description': 'Weight $weight kg appears $count times for customer $customer on $date',
                'severity': 'medium',
                'date': date,
                'customer': customer,
                'weight': weight,
                'count': count,
              });
            }
          });
        });
      });
      
      // Check for missed collections (no harvest for more than 7 days)
      final now = DateTime.now();
      final customersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'customer').get();
      
      for (var customerDoc in customersSnapshot.docs) {
        final customerData = customerDoc.data();
        final regNo = customerData['regNo']?.toString();
        
        if (regNo != null) {
          final lastHarvestQuery = await _firestore
              .collection('harvest_value')
              .where('customerRegNo', isEqualTo: regNo)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (lastHarvestQuery.docs.isNotEmpty) {
            final lastHarvest = lastHarvestQuery.docs.first;
            final lastHarvestDate = (lastHarvest.data()['createdAt'] as Timestamp).toDate();
            final daysDifference = now.difference(lastHarvestDate).inDays;
            
            if (daysDifference > 7) {
              newAlerts.add({
                'type': 'missed_collection',
                'title': 'Missed Collection Alert',
                'description': 'Customer $regNo has no collections for $daysDifference days',
                'severity': 'low',
                'customer': regNo,
                'daysMissed': daysDifference,
              });
            }
          } else {
            // Customer has never had any harvests
            newAlerts.add({
              'type': 'no_collection',
              'title': 'No Collections Found',
              'description': 'Customer $regNo has never had any collections',
              'severity': 'medium',
              'customer': regNo,
            });
          }
        }
      }
      
      if (mounted) {
        setState(() {
          alerts = newAlerts;
        });
      }
    } catch (e) {
      print('Error checking alerts: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    
    await _loadStatisticsManually();
    await _checkForAlerts();
    
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await _auth.signOut();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                print('Error signing out: $e');
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildDashboardHome(),
    );
  }

  Widget _buildDashboardHome() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Admin!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            Text(
              'Good ${_getTimeGreeting()}! Real-time dashboard',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            
            // Today's Activity Summary
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTodayInfo('New Users', todayUsers, Icons.person_add),
                      _buildTodayInfo('Harvests', todayHarvests, Icons.eco),
                    ],
                  ),
                ],
              ),
            ),
            
            // Alerts Summary
            if (alerts.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${alerts.length} alert(s) require attention',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CheckAlertsPage()),
                      ),
                      child: Text('View'),
                    ),
                  ],
                ),
              ),
            
            // Statistics Cards (Real-time updated, excluding admin from Total Users)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard('Total Users', totalUsers, Icons.people, Colors.blue),
                _buildStatCard('Customers', totalCustomers, Icons.person, Colors.green),
                _buildStatCard('Collectors', totalCollectors, Icons.agriculture, Colors.orange),
                _buildStatCard('Total Harvests', totalHarvests, Icons.eco, Colors.purple),
                _buildStatCard('Payments', totalPayments, Icons.payment, Colors.teal),
                _buildStatCard('Active Alerts', alerts.length, Icons.warning, Colors.red),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildActionCard('Manage Users', Icons.people_alt, () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageUsersPage()),
                )),
                _buildActionCard('View Harvests', Icons.eco, () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewHarvestsPage()),
                )),
                _buildActionCard('Check Alerts', Icons.warning, () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckAlertsPage()),
                )),
                _buildActionCard('Payments', Icons.payment, () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentsPage()),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayInfo(String title, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.blue[600]),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
      
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.green[600]),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}