import 'dart:io';
import 'package:TeaLink/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:TeaLink/pages/login_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> 
    with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  String? displayName;
  String currentDate = '';
  int _selectedIndex = 0;

  File? _profileImage;
  String weeklyHarvest = '...';
  
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Add a GlobalKey for the ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchWeeklyHarvest();
    formatDate();
    _loadProfileImage();
    
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
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void formatDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy\nEEEE').format(now);
    setState(() => currentDate = formattedDate);
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (mounted) {
          setState(() => displayName = doc.data()?['name'] ?? 'User');
        }
      } catch (e) {
        if (mounted) {
          setState(() => displayName = 'User');
        }
      }
    }
  }

  Future<void> fetchWeeklyHarvest() async {
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        final regNo = userDoc.data()?['registrationNumber'];
        if (regNo == null || regNo.isEmpty) {
          if (mounted) {
            setState(() => weeklyHarvest = '0kg');
          }
          return;
        }

        final now = DateTime.now();
        // Fixed week calculation - using proper ISO week calculation
        final weekId = "${now.year}-W${_getWeekNumber(now)}";

        final weeklyDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(regNo)
            .collection('weekly')
            .doc(weekId)
            .get();

        if (mounted) {
          setState(() {
            weeklyHarvest = "${weeklyDoc.data()?['total'] ?? 0}kg";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => weeklyHarvest = '0kg');
        }
      }
    }
  }

  // Helper method for proper week calculation
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear - 1) / 7).ceil();
  }

  Future<void> _loadProfileImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_image.png';
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        if (mounted) {
          setState(() => _profileImage = imageFile);
        }
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

      if (mounted) {
        setState(() => _profileImage = savedImage);
        _showSuccessSnackBar('Profile picture updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update profile picture');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/customer_home');
        break;
      case 1:
        Navigator.pushNamed(context, '/customer_trends');
        break;
      case 2:
        Navigator.pushNamed(context, '/customer_payments');
        break;
      case 3:
        Navigator.pushNamed(context, '/customer_profile');
        break;
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // Get current location with proper error handling
  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled. Please enable them.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied.');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied.');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error getting location: $e');
      _showErrorSnackBar('Failed to get location. Please try again.');
      return null;
    }
  }

  // Show location save dialog
  Future<bool> _showLocationSaveDialog(Map<String, double> locationData) async {
    final TextEditingController addressController = TextEditingController();
    bool saveLocation = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Save Your Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We detected you don\'t have a saved location. Would you like to save your current location for future notifications?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Coordinates: ${locationData['latitude']!.toStringAsFixed(6)}, ${locationData['longitude']!.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                hintText: 'Enter your address or location description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.home),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              saveLocation = false;
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              saveLocation = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Location'),
          ),
        ],
      ),
    );

    if (saveLocation) {
      await _saveLocationToUser(locationData, addressController.text.trim());
      return true;
    }
    return false;
  }

  // Save location to user document
  Future<void> _saveLocationToUser(Map<String, double> locationData, String address) async {
    try {
      Map<String, dynamic> updateData = {
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'locationUpdatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (address.isNotEmpty) {
        updateData['location'] = address;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);
      
      _showSuccessSnackBar('Location saved successfully!');
    } catch (e) {
      print('Error saving location: $e');
      _showErrorSnackBar('Failed to save location: ${e.toString()}');
    }
  }

  Future<void> _notifyCollector(BuildContext context) async {
    if (user == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final regNo = userDoc.data()?['registrationNumber'];
      final name = userDoc.data()?['name'] ?? 'Unknown';
      
      // Get user's stored location from the user document
      final userLatitude = userDoc.data()?['latitude'];
      final userLongitude = userDoc.data()?['longitude'];
      String? userLocationAddress = userDoc.data()?['location'];

      String? collectorId;
      
      try {
        final connectionQuery = await FirebaseFirestore.instance
            .collection('customer_collector_connections')
            .where('customerId', isEqualTo: user!.uid)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (connectionQuery.docs.isNotEmpty) {
          collectorId = connectionQuery.docs.first.data()['collectorId'];
        }
      } catch (e) {
        print('Error getting collector connection: $e');
      }

      if (regNo == null || regNo.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          // Use a delay to ensure the dialog is closed before showing SnackBar
          Future.delayed(const Duration(milliseconds: 100), () {
            _showErrorSnackBar('Registration number not found. Please update your profile.');
          });
        }
        return;
      }

      if (collectorId == null || collectorId.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          // Use a delay to ensure the dialog is closed before showing SnackBar
          Future.delayed(const Duration(milliseconds: 100), () {
            _showErrorSnackBar('No active collector assigned. Please contact admin.');
          });
        }
        return;
      }

      // Check if user has stored location
      Map<String, double>? locationToUse;
      bool hasStoredLocation = userLatitude != null && userLongitude != null;
      
      if (hasStoredLocation) {
        // User has stored location
        locationToUse = {
          'latitude': userLatitude.toDouble(),
          'longitude': userLongitude.toDouble(),
        };
      } else {
        // User doesn't have stored location, get current location
        if (mounted) {
          Navigator.pop(context); // Close loading dialog first
        }
        
        Map<String, double>? currentLocationData = await _getCurrentLocation();
        
        if (currentLocationData == null) {
          _showErrorSnackBar('Location is required to notify the collector.');
          return;
        }

        // Show dialog to save location
        bool locationSaved = await _showLocationSaveDialog(currentLocationData);
        
        // Show loading dialog again
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        locationToUse = currentLocationData;
        
        // If user chose to save location, update the location source
        if (locationSaved) {
          // Refresh user data to get the saved location info
          final updatedUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
          
          final updatedAddress = updatedUserDoc.data()?['location'];
          if (updatedAddress != null) {
            userLocationAddress = updatedAddress;
          }
        }
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('HH:mm:ss').format(now);

      // Prepare notification data
      Map<String, dynamic> notificationData = {
        'customerId': user!.uid, 
        'name': name,
        'regNo': regNo,
        'collectorId': collectorId,
        'date': formattedDate,
        'time': formattedTime,
        'status': 'Pending', 
        'createdAt': Timestamp.fromDate(now),
      };

      // Add location field
      if (locationToUse != null) {
        Map<String, dynamic> locationField = {
          'latitude': locationToUse['latitude'],
          'longitude': locationToUse['longitude'],
          'timestamp': Timestamp.fromDate(now),
          'source': hasStoredLocation ? 'stored' : 'current',
        };
        
        // Add address if available
        if (userLocationAddress != null && userLocationAddress.isNotEmpty) {
          locationField['address'] = userLocationAddress;
        }
        
        notificationData['location'] = locationField;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('notify_for_collection')
          .add(notificationData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Use a delay to ensure the dialog is closed before showing success dialog
        Future.delayed(const Duration(milliseconds: 100), () {
          _showSuccessDialog();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
      }
      print('Error in _notifyCollector: $e');
      // Use a delay to ensure any dialogs are closed before showing SnackBar
      Future.delayed(const Duration(milliseconds: 100), () {
        _showErrorSnackBar('Failed to notify collector. Please try again.');
      });
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'The collector has been notified about today\'s harvest. They will contact you soon.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    // Use the ScaffoldMessenger key to ensure we have a valid context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    // Use the ScaffoldMessenger key to ensure we have a valid context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scaffoldMessengerKey.currentState != null) {
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Add logout method that was missing
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to logout. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _logout(context);
        return false;
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          
          appBar: AppBar(
            backgroundColor: kMainColor,
            elevation: 0,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Text(
                'CUSTOMER DASHBOARD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => _logout(context),
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
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  onPressed: () => _logout(context),
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
              // Header Section
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: _animationController != null
                        ? FadeTransition(
                            opacity: _fadeAnimation!,
                            child: SlideTransition(
                              position: _slideAnimation!,
                              child: _buildHeaderContent(),
                            ),
                          )
                        : _buildHeaderContent(),
                  ),
                ),
              ),

              // Dashboard Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: _animationController != null
                        ? FadeTransition(
                            opacity: _fadeAnimation!,
                            child: SlideTransition(
                              position: _slideAnimation!,
                              child: _buildDashboardContent(),
                            ),
                          )
                        : _buildDashboardContent(),
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom Navigation
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
                backgroundColor: Colors.transparent,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: kMainColor,
                unselectedItemColor: Colors.grey,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded, size: 24),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.trending_up, size: 24),
                    label: 'Trends',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.payments, size: 24),
                    label: 'Payments',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person, size: 24),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${displayName ?? 'Loading...'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                getGreeting(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _notifyCollector(context),
                  icon: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                  label: const Text(
                    "Notify Collector",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Profile Avatar
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 37,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndSaveImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, color: kMainColor, size: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Track your tea farming progress",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 25),
        
        // Dashboard Cards - Fixed overflow issue
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedDashboardCard(
                        title: "Weekly Harvest",
                        subtitle: currentDate,
                        value: weeklyHarvest,
                        icon: null,
                        color: Colors.white,
                        delay: 0,
                        maxWidth: constraints.maxWidth / 2 - 8,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEnhancedDashboardCard(
                        title: "Harvest Trends",
                        subtitle: "View analytics",
                        icon: Icons.trending_up,
                        color: Colors.blue,
                        delay: 100,
                        maxWidth: constraints.maxWidth / 2 - 8,
                        onTap: () => Navigator.pushNamed(context, '/customer_trends'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedDashboardCard(
                        title: "Payments",
                        subtitle: "View transactions",
                        icon: Icons.payment,
                        color: Colors.orange,
                        delay: 200,
                        maxWidth: constraints.maxWidth / 2 - 8,
                        onTap: () => Navigator.pushNamed(context, '/customer_payments'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEnhancedDashboardCard(
                        title: "Collector Info",
                        subtitle: "Contact details",
                        icon: Icons.person_outline,
                        color: Colors.purple,
                        delay: 300,
                        maxWidth: constraints.maxWidth / 2 - 8,
                        onTap: () => Navigator.pushNamed(context, '/customer_collector_info'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        
        // Additional features section
        _buildFeatureSection(),
      ],
    );
  }

  Widget _buildFeatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: kMainColor, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tea Collection Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your weekly harvest of $weeklyHarvest is ready for collection. Use the "Notify Collector" button to alert your assigned collector.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDashboardCard({
    required String title,
    String? subtitle,
    String? value,
    IconData? icon,
    required Color color,
    required int delay,
    required double maxWidth,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: 120,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color == Colors.white ? kMainColor : color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}