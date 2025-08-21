import 'dart:io';
import 'package:TeaLink/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CollectorProfile extends StatefulWidget {
  const CollectorProfile({super.key});

  @override
  State<CollectorProfile> createState() => _CollectorProfileState();
}

class _CollectorProfileState extends State<CollectorProfile> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  String? profileImageUrl;
  String? registrationNumber;
  int _selectedIndex = 3;

  

  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool isLoading = true;
  
  void _editName() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: nameController,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  setState(() {}); // Refresh UI
                  Navigator.pop(ctx);
                },
                child: const Text("Save")),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
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
          'profileImage': '',
          'registrationNumber': regNum,
        });

        setState(() {
          registrationNumber = regNum;
          nameController.text = user.displayName ?? '';
          phoneController.text = '';
          profileImageUrl = '';
        });
      } else {
        setState(() {
          nameController.text = doc['name'] ?? '';
          phoneController.text = doc['phone'] ?? '';
          registrationNumber = doc['registrationNumber'] ?? '';
          profileImageUrl = doc['profileImage'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() {
        registrationNumber = '';
      });
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

  Future<void> _saveProfile() async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'profileImage': profileImageUrl ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Enter your password to confirm account deletion."),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: passwordController.text);
      await user.reauthenticateWithCredential(cred);

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
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kMainColor,
        title: const Text("PROFILE",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
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
            _editableTile("Name", nameController, _editName),
            const SizedBox(height: 8),
            _detailTile("Email", user.email ?? '', null, readOnly: true),
            const SizedBox(height: 8),
            _editableTile("Phone Number", phoneController, _editPhone),
            _detailTile("Unique Registration Number", registrationNumber ?? '',
                null, readOnly: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: kWhite,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15)),
              child: const Text(
                "Save",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w900),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: kMainColor,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Colors.grey[200],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_sharp),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
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
      trailing: onEdit != null && !readOnly
          ? IconButton(icon: const Icon(Icons.edit), onPressed: onEdit)
          : null,
    );
  }

  Widget _editableTile(String title, TextEditingController controller, VoidCallback? onEdit) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(controller.text, style: const TextStyle(fontSize: 13)),
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

  void _onItemTapped(int index) {
  setState(() => _selectedIndex = index);

  switch (index) {
    case 0:
      Navigator.pushNamed(context, '/collector_home');// Already on home
    case 1:
      Navigator.pushNamed(context, '/collector_map');
      break;
    case 2:
      Navigator.pushNamed(context, '/collector_history');
      break;
    case 3:
      Navigator.pushNamed(context, '/collector_profile'); // Profile page route
      break;
  }
}

}
