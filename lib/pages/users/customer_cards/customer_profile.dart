import 'dart:io';
import 'package:TeaLink/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  String? profileImageUrl;
  String? registrationNumber;
  String? address;
  double? latitude;
  double? longitude;
  int _selectedIndex = 3;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool isLoading = true;
  bool _showQR = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/customer_home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/customer_trends');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/customer_payments');
        break;
      case 3:
        // Already on profile page
        break;
    }
  }

  Future<void> _loadProfile() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _createNewUserDocument();
      } else {
        await _loadExistingUserData(doc);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _generateFallbackRegistrationNumber();
      _showErrorSnackBar('Error loading profile. Please check your internet connection.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _createNewUserDocument() async {
    String regNum = _generateRegistrationNumber();
    
    await _firestore.collection('users').doc(user.uid).set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'location': '',
      'latitude': null,
      'longitude': null,
      'profileImage': '',
      'registrationNumber': regNum,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        registrationNumber = regNum;
        nameController.text = user.displayName ?? '';
        phoneController.text = '';
        profileImageUrl = '';
        address = '';
      });
    }
  }

  Future<void> _loadExistingUserData(DocumentSnapshot doc) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    if (mounted) {
      setState(() {
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        registrationNumber = data['registrationNumber'];
        profileImageUrl = data['profileImage'] ?? '';
        address = data['location'] ?? '';
        latitude = data['latitude'];
        longitude = data['longitude'];
      });
    }

    if (registrationNumber == null || registrationNumber!.isEmpty) {
      String regNum = _generateRegistrationNumber();
      
      await _firestore.collection('users').doc(user.uid).update({
        'registrationNumber': regNum,
      });

      if (mounted) {
        setState(() {
          registrationNumber = regNum;
        });
      }
    }
  }

  String _generateRegistrationNumber() {
    return 'TEA${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  void _generateFallbackRegistrationNumber() {
    String fallbackRegNum = _generateRegistrationNumber();
    if (mounted) {
      setState(() {
        registrationNumber = fallbackRegNum;
      });
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  ? Image.network(
                      profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: 50, color: Colors.grey[600]);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: kMainColor,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : Icon(Icons.person, size: 50, color: Colors.grey[600]),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt, color: kMainColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (pickedFile == null) return;

      _showLoadingSnackBar('Uploading image...');

      File file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profilePics/${user.uid}.jpg');
      
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => profileImageUrl = downloadUrl);
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessSnackBar('Profile image updated successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  Future<void> _pickLocation() async {
    try {
      LatLng? picked = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (_) => const OSMLocationPickerPage(),
        ),
      );

      if (picked != null) {
        _showLoadingSnackBar('Getting location details...');
        
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            picked.latitude, 
            picked.longitude
          );
          
          String fullAddress = '';
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            List<String> addressParts = [];
            
            if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
            if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
            if (place.administrativeArea?.isNotEmpty == true) addressParts.add(place.administrativeArea!);
            if (place.country?.isNotEmpty == true) addressParts.add(place.country!);
            
            fullAddress = addressParts.join(', ');
          }
          
          if (fullAddress.isEmpty) {
            fullAddress = 'Location: ${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
          }

          setState(() {
            address = fullAddress;
            latitude = picked.latitude;
            longitude = picked.longitude;
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSuccessSnackBar('Location updated successfully!');
        } catch (e) {
          String coordsAddress = 'Location: ${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
          
          setState(() {
            address = coordsAddress;
            latitude = picked.latitude;
            longitude = picked.longitude;
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSuccessSnackBar('Location coordinates saved!');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to pick location: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return;
    }

    try {
      _showLoadingSnackBar('Saving profile...');

      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'profileImage': profileImageUrl ?? '',
        'location': address ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to update profile: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 28),
              const SizedBox(width: 8),
              const Text("Delete Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This action cannot be undone. Please enter your password to confirm.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Enter your password",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(ctx, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete Account", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        passwordController.dispose();
        return;
      }

      _showLoadingSnackBar('Deleting account...');

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );
      await user.reauthenticateWithCredential(cred);

      if (profileImageUrl?.isNotEmpty == true) {
        try {
          await FirebaseStorage.instance.refFromURL(profileImageUrl!).delete();
        } catch (e) {
          debugPrint('Error deleting profile image: $e');
        }
      }

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      passwordController.dispose();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      passwordController.dispose();
      _showErrorSnackBar('Error deleting account: $e');
    }
  }

  void _editName() {
    final tempController = TextEditingController(text: nameController.text);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.edit, color: kMainColor, size: 24),
              const SizedBox(width: 8),
              const Text("Edit Name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: tempController,
              decoration: const InputDecoration(
                hintText: "Enter your name",
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                tempController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempController.text.trim().isNotEmpty) {
                  setState(() {
                    nameController.text = tempController.text.trim();
                  });
                }
                tempController.dispose();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _editPhone() {
    final tempController = TextEditingController(text: phoneController.text);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.phone, color: kMainColor, size: 24),
              const SizedBox(width: 8),
              const Text("Edit Phone Number", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: tempController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Enter your phone number",
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                tempController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  phoneController.text = tempController.text.trim();
                });
                tempController.dispose();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kMainColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kMainColor),
              const SizedBox(height: 16),
              Text(
                "Loading your profile...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: kMainColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kWhite),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kMainColor, kMainColor.withOpacity(0.8)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildProfileImage(),
                      const SizedBox(height: 12),
                      Text(
                        nameController.text.isNotEmpty ? nameController.text : "Welcome!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Personal Information", Icons.person),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildEditableField("Full Name", nameController.text, Icons.person, _editName),
                    _buildReadOnlyField("Email Address", user.email ?? '', Icons.email),
                    _buildEditableField("Phone Number", phoneController.text.isEmpty ? "Add phone number" : phoneController.text, Icons.phone, _editPhone),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader("Location & QR Code", Icons.location_on),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildEditableField(
                      "Current Location",
                      address?.isEmpty == true ? "Add your location" : address ?? "Add your location",
                      Icons.location_on,
                      _pickLocation
                    ),
                    _buildReadOnlyField(
                      "Registration ID",
                      registrationNumber?.isNotEmpty == true
                          ? registrationNumber!
                          : "Generating...",
                      Icons.qr_code
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildQRSection(),

                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
          backgroundColor: Colors.white,
          selectedItemColor: kMainColor,
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Trends'),
            BottomNavigationBarItem(icon: Icon(Icons.payment_rounded), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kMainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kMainColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(
            children: [
              child,
              if (index < children.length - 1)
                Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, IconData icon, VoidCallback? onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value.isEmpty ? "Tap to add" : value,
        style: TextStyle(
          fontSize: 16,
          color: value.isEmpty ? Colors.grey[500] : Colors.black87,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kMainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.edit, color: kMainColor, size: 18),
      ),
      onTap: onTap,
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(Icons.lock_outline, color: Colors.grey[400], size: 18),
    );
  }

  Widget _buildQRSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.qr_code, color: kMainColor, size: 20),
            ),
            title: const Text(
              "My QR Code",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text("Share this QR code for easy identification"),
            trailing: IconButton(
              icon: Icon(_showQR ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: () => setState(() => _showQR = !_showQR),
            ),
          ),
          if (_showQR) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: registrationNumber?.isNotEmpty == true
                    ? QrImageView(
                        data: registrationNumber!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            "Generating QR Code...",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _deleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  "Delete Account",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// OSM Location Picker Page
class OSMLocationPickerPage extends StatefulWidget {
  const OSMLocationPickerPage({super.key});

  @override
  State<OSMLocationPickerPage> createState() => _OSMLocationPickerPageState();
}

class _OSMLocationPickerPageState extends State<OSMLocationPickerPage> {
  LatLng? selectedPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Choose Location",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kMainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: selectedPosition != null
                  ? () => Navigator.pop(context, selectedPosition)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kMainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(6.9271, 79.8612), // Default to Sri Lanka (Colombo)
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedPosition = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tealink.app',
                maxZoom: 19,
              ),
              if (selectedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kMainColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search for a location...",
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _searchLocation(value.trim());
                  }
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          // Current location button
          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: kMainColor,
              elevation: 5,
              child: const Icon(Icons.my_location),
            ),
          ),
          // Instruction or info card
          if (selectedPosition == null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: kMainColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Tap on the map to select your location",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kMainColor),
                        const SizedBox(width: 8),
                        const Text(
                          "Selected Location",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Lat: ${selectedPosition!.latitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "Lng: ${selectedPosition!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        _mapController.move(latLng, 15.0);

        setState(() {
          selectedPosition = latLng;
        });

        _showSuccessSnackBar('Location found!');
      } else {
        _showErrorSnackBar('Location not found. Try a different search term.');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      _showErrorSnackBar('Failed to search location. Please try again.');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDisabledDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      _showLoadingSnackBar('Getting your location...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      _mapController.move(latLng, 16.0);

      setState(() {
        selectedPosition = latLng;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessSnackBar('Current location found!');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      String errorMessage = 'Failed to get current location';

      if (e.toString().contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Location permission denied';
      } else if (e.toString().contains('service')) {
        errorMessage = 'Location services are disabled';
      }

      _showErrorSnackBar(errorMessage);
      debugPrint('Location error: $e');
    }
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This feature needs location permission to work properly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _getCurrentLocation();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission has been permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: kMainColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}