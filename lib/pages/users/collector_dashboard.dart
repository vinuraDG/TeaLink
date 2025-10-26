import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/pages/login_page.dart';


class CollectorDashboard extends StatefulWidget {
  const CollectorDashboard({super.key});

  @override
  State<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String userName = "";
  String greeting = ""; // Default empty, will be set after build
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    _animationController!.forward();
    
    // Use WidgetsBinding to delay initialization until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setGreeting();
        _fetchUserName();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _setGreeting() {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    
    if (mounted) {
      setState(() {
        if (hour < 12) {
          greeting = l10n.goodMorning;
        } else if (hour < 17) {
          greeting = l10n.goodAfternoon;
        } else {
          greeting = l10n.goodEvening;
        }
      });
    }
  }

  Future<void> _fetchUserName() async {
    if (!mounted) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null && mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            userName = doc['name'] ?? l10n.user ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/collector_map');
        break;
      case 2:
        Navigator.pushNamed(context, '/collector_history');
        break;
      case 3:
        Navigator.pushNamed(context, '/collector_profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // Enhanced AppBar with proper structure
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            l10n.collectorDashboard,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kWhite,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kWhite, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: kWhite, size: 20),
              onPressed: () => _showLogoutDialog(),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kMainColor,
                kMainColor.withOpacity(0.8),
                kMainColor.withOpacity(0.9),
              ],
            ),
          ),
        ),
      ),
      
      body: Column(
        children: [
          // Enhanced Header Section (without top app bar elements)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kMainColor,
                  kMainColor.withOpacity(0.8),
                  kMainColor.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: kMainColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                children: [
                  // Enhanced Greeting Section
                  _animationController != null
                      ? FadeTransition(
                          opacity: _fadeAnimation!,
                          child: SlideTransition(
                            position: _slideAnimation!,
                            child: _buildGreetingRow(l10n),
                          ),
                        )
                      : _buildGreetingRow(l10n),
                ],
              ),
            ),
          ),

          // Enhanced Dashboard Cards Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _animationController != null
                    ? FadeTransition(
                        opacity: _fadeAnimation!,
                        child: SlideTransition(
                          position: _slideAnimation!,
                          child: _buildDashboardContent(l10n, screenWidth),
                        ),
                      )
                    : _buildDashboardContent(l10n, screenWidth),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: kMainColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 26),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_sharp, size: 26),
                label: l10n.map,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history, size: 26),
                label: l10n.history,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person, size: 26),
                label: l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting.isEmpty ? "Hello!" : greeting,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName.isEmpty ? (l10n.loading) : userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kWhite,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  l10n.readyToCollectToday,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Enhanced Profile Avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kWhite, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              image: const DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/avatar.jpg'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(AppLocalizations l10n, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseActionToStart,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 25),
        
        // Grid Cards - Using shrinkWrap instead of fixed height
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: screenWidth > 400 ? 1.1 : 1.0,
          children: [
            _buildEnhancedDashboardCard(
              title: l10n.customerList,
              subtitle: l10n.viewAllCustomers,
              icon: Icons.people,
              color: Colors.blue,
              delay: 0,
              onTap: () => Navigator.pushNamed(
                context,
                '/collector_customer_list',
              ),
            ),
            _buildEnhancedDashboardCard(
              title: l10n.history,
              subtitle: l10n.viewPastCollections,
              icon: Icons.history,
              color: Colors.purple,
              delay: 300,
              onTap: () => Navigator.pushNamed(
                context,
                '/collector_history',
              ),
            ),
            _buildEnhancedDashboardCard(
              title: l10n.mapView,
              subtitle: l10n.seeCustomerLocations,
              icon: Icons.map_outlined,
              color: Colors.orange,
              delay: 200,
              onTap: () => Navigator.pushNamed(
                context,
                '/collector_map',
              ),
            ),
            _buildEnhancedDashboardCard(
              title: l10n.profileSettings,
              subtitle: l10n.manageCollectorProfile,
              icon: Icons.settings,
              color: kMainColor,
              delay: 300,
              onTap: () => Navigator.pushNamed(
                context,
                '/collector_profile',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

void _showLogoutDialog() {
  if (!mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Center(
          child: Text(
            l10n.logout,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          l10n.areYouSureLogout,
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
                    l10n.cancel,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(l10n.logout),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
}

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}