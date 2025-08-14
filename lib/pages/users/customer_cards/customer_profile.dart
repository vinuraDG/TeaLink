import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

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

  void _onTabSelected(int index) {
  if (_selectedIndex == index) return; // already on selected page
  setState(() => _selectedIndex = index);

  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, '/Home');
      break;
    case 1:
      Navigator.pushReplacementNamed(context, '/Trends');
      break;
    case 2:
      Navigator.pushReplacementNamed(context, '/Payments');
      break;
    case 3:
      // Already on profile
      break;
  }
}

  late TextEditingController phoneController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        String regNum = const Uuid().v4();
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': '',
          'location': '',
          'latitude': null,
          'longitude': null,
          'profileImage': '',
          'registrationNumber': '',
        });
        
      } else {
        phoneController.text = doc['phone'] ?? '';
        registrationNumber = doc['registrationNumber'] ?? '';
        profileImageUrl = doc['profileImage'] ?? '';
        address = doc['location'] ?? '';
        latitude = doc['latitude'];
        longitude = doc['longitude'];
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      registrationNumber = '';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    final ref =
        FirebaseStorage.instance.ref().child('profilePics/${user.uid}.jpg');
    await ref.putFile(file);
    String downloadUrl = await ref.getDownloadURL();

    setState(() => profileImageUrl = downloadUrl);
  }

  Future<void> _pickLocation() async {
    LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (picked != null) {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(picked.latitude, picked.longitude);
      String fullAddress =
          "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}";

      setState(() {
        address = fullAddress;
        latitude = picked.latitude;
        longitude = picked.longitude;
      });
    }
  }

  Future<void> _saveProfile() async {
    await _firestore.collection('users').doc(user.uid).update({
      'phone': phoneController.text,
      'profileImage': profileImageUrl ?? '',
      'location': address ?? '',
      'latitude': latitude,
      'longitude': longitude,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account permanently?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("PROFILE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (profileImageUrl != null &&
                        profileImageUrl!.isNotEmpty)
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/images/avatar.jpg')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 8),
            Text(user.displayName ?? "User",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email ?? "",
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            _detailTile("Phone Number", phoneController.text, _editPhone),
            _detailTile("Unique Registration Number", registrationNumber ?? '',
                null,
                readOnly: true),
            _detailTile("Location", address ?? 'Tap to pick location',
                _pickLocation),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: registrationNumber ?? '',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _saveProfile,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: _deleteAccount,
              child: const Text("Delete Account",
                  style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: _onTabSelected,
  backgroundColor: Colors.grey[200],
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
    );
  }

  Widget _detailTile(String title, String value, VoidCallback? onEdit,
      {bool readOnly = false}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 13)),
      trailing: onEdit != null
          ? IconButton(icon: const Icon(Icons.edit), onPressed: onEdit)
          : null,
    );
  }

  void _editPhone() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Phone"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text("Save")),
          ],
        );
      },
    );
  }
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? selectedPosition;
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Colors.green,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedPosition);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(40.7128, -74.0060), // Default NYC
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
        onTap: (pos) {
          setState(() {
            selectedPosition = pos;
          });
        },
        markers: selectedPosition != null
            ? {
                Marker(markerId: const MarkerId("selected"), position: selectedPosition!)
              }
            : {},
      ),
    );
  }
}
