import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:TeaLink/pages/login_page.dart';
import 'package:TeaLink/pages/users/admin_card/admin_payment.dart';
import 'package:TeaLink/pages/users/admin_card/admin_setting.dart';
import 'package:TeaLink/pages/users/admin_card/alert.dart';
import 'package:TeaLink/pages/users/admin_card/manage_users.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Statistics
  int totalUsers = 0;
  int totalCustomers = 0;
  int totalCollectors = 0;
  int totalPayments = 0;
  int todayUsers = 0;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _paymentsSubscription;
  Timer? _alertTimer;

  // Animation Controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeRealTimeData();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _paymentsSubscription?.cancel();
    _alertTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _initializeRealTimeData() {
    setState(() {
      isLoading = true;
    });

    _setupRealTimeListeners();
    _checkForAlerts();

    _alertTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkForAlerts();
    });
  }

  void _setupRealTimeListeners() {
    _loadStatisticsManually().then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      _checkAdminStatus().then((isAdminUser) {
        if (!isAdminUser) {
          print('User is not admin, using manual data loading only');
          return;
        }

        _usersSubscription =
            _firestore.collection('users').snapshots().listen((snapshot) {
          if (mounted) _updateUserStatistics(snapshot);
        }, onError: (e) => print('Error listening to users: $e'));

        _paymentsSubscription =
            _firestore.collection('payments').snapshots().listen((snapshot) {
          if (mounted) {
            setState(() {
              totalPayments = snapshot.docs.length;
            });
          }
        }, onError: (e) => print('Error listening to payments: $e'));
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
      return (userData['role']?.toString().toLowerCase() ?? '') == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> _loadStatisticsManually() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final paymentsSnapshot = await _firestore.collection('payments').get();

      int customers = 0;
      int collectors = 0;
      int usersToday = 0;
      final startOfDay =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role']?.toString().toLowerCase() ?? '';
        bool isNewToday = false;
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime userCreatedDate = (createdAt is Timestamp)
              ? createdAt.toDate()
              : DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
          if (userCreatedDate.isAfter(startOfDay)) {
            isNewToday = true;
          }
        }

        if (role == 'customer') {
          customers++;
          if (isNewToday) usersToday++;
        } else if (role == 'collector') {
          collectors++;
          if (isNewToday) usersToday++;
        }
      }

      if (mounted) {
        setState(() {
          totalUsers = customers + collectors;
          totalCustomers = customers;
          totalCollectors = collectors;
          todayUsers = usersToday;
          totalPayments = paymentsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading statistics manually: $e');
    }
  }

  void _updateUserStatistics(QuerySnapshot snapshot) {
    int customers = 0;
    int collectors = 0;
    int usersToday = 0;
    final startOfDay =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role']?.toString().toLowerCase() ?? '';
      bool isNewToday = false;
      final createdAt = data['createdAt'];
      if (createdAt != null) {
        DateTime userCreatedDate = (createdAt is Timestamp)
            ? createdAt.toDate()
            : DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
        if (userCreatedDate.isAfter(startOfDay)) {
          isNewToday = true;
        }
      }
      if (role == 'customer') {
        customers++;
        if (isNewToday) usersToday++;
      } else if (role == 'collector') {
        collectors++;
        if (isNewToday) usersToday++;
      }
    }

    setState(() {
      totalUsers = customers + collectors;
      totalCustomers = customers;
      totalCollectors = collectors;
      todayUsers = usersToday;
    });
  }

  Future<void> _checkForAlerts() async {
    // Keep your original alert logic here
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _loadStatisticsManually();
    await _checkForAlerts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(localizations),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: kMainColor))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: kMainColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(localizations),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAnimatedDashboardContent(localizations),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(localizations),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
   return AppBar(
  backgroundColor: kMainColor,
  elevation: 0,
  automaticallyImplyLeading: false, // Add this line
  title: Text(
    localizations.dashboard,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: kWhite,
    ),
  ),
  centerTitle: true,
  
  actions: [
    IconButton(
      icon: Icon(Icons.notifications_outlined, color: kWhite),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AlertsPage()),
      ),
    ),
    IconButton(
      icon: Icon(Icons.logout_rounded, color: kWhite),
      onPressed: () => _showLogoutDialog(localizations),
    ),
  ],
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kMainColor, kMainColor.withOpacity(0.8)],
      ),
    ),
  ),
);
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kMainColor, kMainColor.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _animationController != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: _buildGreetingContent(localizations),
              ),
            )
          : _buildGreetingContent(localizations),
    );
  }

  Widget _buildGreetingContent(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getTimeGreeting(localizations)}!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.admin,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kWhite, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/avatar.jpg'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                localizations.realTimeSystemOverview,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDashboardContent(AppLocalizations localizations) {
    return _animationController != null
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: SlideTransition(
              position: _slideAnimation!,
              child: _buildDashboardContent(localizations),
            ),
          )
        : _buildDashboardContent(localizations);
  }

  Widget _buildDashboardContent(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Activity Card
        _buildTodayActivity(localizations),
        const SizedBox(height: 20),

        // Alerts Summary (if any)
        if (alerts.isNotEmpty) ...[
          _buildAlertsSummary(localizations),
          const SizedBox(height: 20),
        ],

        // Statistics Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.overview,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Icon(Icons.analytics_outlined, color: kMainColor),
          ],
        ),
        const SizedBox(height: 16),

        // Statistics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildModernStatCard(
              localizations.totalUsers,
              totalUsers,
              Icons.group_rounded,
              Colors.blue,
              Colors.blue.shade50,
            ),
            _buildModernStatCard(
              localizations.customers,
              totalCustomers,
              Icons.person_outline_rounded,
              Colors.green,
              Colors.green.shade50,
            ),
            _buildModernStatCard(
              localizations.collectors,
              totalCollectors,
              Icons.agriculture_rounded,
              Colors.orange,
              Colors.orange.shade50,
            ),
            _buildModernStatCard(
              localizations.payments,
              totalPayments,
              Icons.payments_rounded,
              Colors.purple,
              Colors.purple.shade50,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Quick Actions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.quickActionsTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Icon(Icons.flash_on_rounded, color: kMainColor),
          ],
        ),
        const SizedBox(height: 16),

        // Action Cards
        _buildModernActionCard(
          localizations.manageUsers,
          localizations.viewAndManageUsers,
          Icons.people_alt_rounded,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageUsersPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildModernActionCard(
          localizations.uploadPaymentSlip,
          localizations.checkPaymentRecords,
          Icons.receipt_long_rounded,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminPaymentSlipPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildModernActionCard(
          localizations.systemAlerts,
          localizations.monitorSystemNotifications,
          Icons.notification_important_rounded,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AlertsPage()),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTodayActivity(AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.today_rounded, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                localizations.todaysActivity,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTodayInfo(localizations.newUsers, todayUsers, Icons.person_add_rounded),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildTodayInfo(localizations.activeAlerts, alerts.length, Icons.warning_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayInfo(String title, int value, IconData icon) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsSummary(AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.activeAlertsTitle,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  localizations.alertsNeedAttention.replaceAll('{count}', alerts.length.toString()),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.red.shade400, size: 18),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AppLocalizations localizations) {
  if (!mounted) return;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Text(
                localizations.logoutTitle,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        content: Text(
          localizations.logoutConfirmation,
          style: TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.cancel,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(localizations.logoutButton),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

  String _getTimeGreeting(AppLocalizations localizations) {
    final hour = DateTime.now().hour;
    if (hour < 12) return localizations.goodMorningAdmin;
    if (hour < 17) return localizations.goodAfternoonAdmin;
    return localizations.goodEveningAdmin;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AdminPaymentSlipPage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ManageUsersPage()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => AdminSettingsPage()));
        break;
    }
  }

  Widget _buildBottomNavBar(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kMainColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: localizations.home),
            BottomNavigationBarItem(
                icon: Icon(Icons.payment_rounded), label: localizations.payments),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_rounded), label: localizations.user),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: localizations.settings),
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
}