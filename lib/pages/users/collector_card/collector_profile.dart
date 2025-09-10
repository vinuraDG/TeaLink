import 'dart:io';
import 'package:TeaLink/constants/colors.dart';
import 'package:TeaLink/l10n/app_localizations.dart';
import 'package:TeaLink/services/language_service.dart';
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
  String? selectedLanguage;
  int _selectedIndex = 3;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool isLoading = true;

  // Language options
  final Map<String, String> _languageOptions = {
    'en': 'English',
    'si': 'සිංහල',
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    // Use WidgetsBinding to ensure the widget tree is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadUserLanguagePreference();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Generate a proper collector registration number
        String regNum = 'COL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': '',
          'profileImage': '',
          'registrationNumber': regNum,
          'userType': 'collector', // Add user type
          'language': 'en', // Default language
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            registrationNumber = regNum;
            nameController.text = user.displayName ?? '';
            phoneController.text = '';
            profileImageUrl = '';
            selectedLanguage = 'en';
          });
        }
      } else {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if registration number exists, if not create one
        String regNum = data['registrationNumber'] as String? ?? '';
        if (regNum.isEmpty) {
          regNum = 'COL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
          await _firestore.collection('users').doc(user.uid).update({
            'registrationNumber': regNum,
          });
        }
        
        if (mounted) {
          setState(() {
            nameController.text = data['name'] as String? ?? '';
            phoneController.text = data['phone'] as String? ?? '';
            registrationNumber = regNum;
            profileImageUrl = data['profileImage'] as String? ?? '';
            selectedLanguage = data['language'] ?? 'en';
          });
        }

        // If language is not set, set default and update Firestore
        if ((selectedLanguage == null || selectedLanguage!.isEmpty) && mounted) {
          await _firestore.collection('users').doc(user.uid).update({
            'language': 'en',
          });

          if (mounted) {
            setState(() {
              selectedLanguage = 'en';
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      // Generate a fallback registration number
      if (mounted) {
        setState(() {
          registrationNumber = 'COL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
          selectedLanguage = 'en'; // Fallback language
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Enhanced method to handle language loading on profile initialization
  Future<void> _loadUserLanguagePreference() async {
    try {
      // Get language from LanguageService with fallback chain
      String? userLanguage = await LanguageService.getLanguageLocally();
      
      // Set default if still null
      userLanguage ??= 'en';
      
      if (mounted) {
        setState(() {
          selectedLanguage = userLanguage;
        });
      }
      
      // Ensure local storage is synced
      await LanguageService.saveLanguageLocally(userLanguage);
      
    } catch (e) {
      debugPrint('Error loading language preference: $e');
      if (mounted) {
        setState(() {
          selectedLanguage = 'en'; // Fallback to English
        });
      }
    }
  }

  void _editName() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit, color: kMainColor, size: 24),
              const SizedBox(width: 8),
              Text(l10n.editName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: l10n.enterYourName,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted) setState(() {});
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  // Method for changing language
  Future<void> _changeLanguage() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.language, color: kMainColor, size: 24),
              const SizedBox(width: 8),
              Text(l10n.language, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languageOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: selectedLanguage,
                activeColor: kMainColor,
                onChanged: (value) async {
                  if (value != null && value != selectedLanguage && mounted) {
                    // Update local state
                    setState(() {
                      selectedLanguage = value;
                    });
                    
                    // Save to both local storage and Firestore
                    try {
                      await LanguageService.saveLanguageLocally(value);
                      await LanguageService.changeLanguage(value);
                      
                      // Update Firestore
                      await _firestore.collection('users').doc(user.uid).update({
                        'language': value,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      
                      Navigator.pop(ctx);
                      if (mounted) {
                        _showSuccessSnackBar(l10n.languageUpdatedSuccessfully);
                        // Show language change dialog
                        _showLanguageChangeDialog();
                      }
                      
                    } catch (e) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        _showErrorSnackBar('Failed to update language: $e');
                      }
                    }
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageChangeDialog() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: kMainColor, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.languageChanged,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          l10n.restartAppForComplete,
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.okay),
            ),
          ),
        ],
      )
    );
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (pickedFile == null) return;

      if (mounted) _showLoadingSnackBar(l10n.uploadingImage);

      File file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profilePics/${user.uid}.jpg');
      
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      if (mounted) {
        setState(() => profileImageUrl = downloadUrl);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSuccessSnackBar(l10n.profileImageUpdatedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('${l10n.failedToUploadImage}: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (nameController.text.trim().isEmpty) {
      _showErrorSnackBar(l10n.nameCannotBeEmpty);
      return;
    }

    try {
      _showLoadingSnackBar(l10n.savingProfile);

      // Ensure language is properly set
      String languageToSave = selectedLanguage ?? 'en';

      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'profileImage': profileImageUrl ?? '',
        'language': languageToSave,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also save language locally
      await LanguageService.saveLanguageLocally(languageToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSuccessSnackBar(l10n.profileUpdatedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('${l10n.failedToUpdateProfile}: $e');
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(l10n.deleteAccountTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.deleteAccountWarning,
              style: const TextStyle(fontSize: 14),
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
                decoration: InputDecoration(
                  labelText: l10n.enterYourPassword,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      _showLoadingSnackBar(l10n.deletingAccount);

      final cred = EmailAuthProvider.credential(
          email: user.email!, password: passwordController.text);
      await user.reauthenticateWithCredential(cred);

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('${l10n.errorDeletingAccount}: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return Scaffold(
        backgroundColor: kWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kMainColor),
              const SizedBox(height: 16),
              Text(l10n.loadingYourProfile, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0,
        title: Text(l10n.profile,
            style: const TextStyle(
                fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kMainColor, kMainColor.withOpacity(0.8)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/images/avatar.jpg')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                            child: Icon(Icons.camera_alt, color: kMainColor, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nameController.text.isEmpty ? l10n.welcome : nameController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? "",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Display Registration Number in header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ID: ${registrationNumber ?? l10n.generating}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Profile Details Section
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.personalInformation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildProfileCard(l10n.fullName, nameController.text, Icons.person, _editName),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildProfileCard(l10n.emailAddress, user.email ?? '', Icons.email, null, readOnly: true),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildProfileCard(l10n.phoneNumber, phoneController.text.isEmpty ? l10n.tapToAdd : phoneController.text, Icons.phone, _editPhone),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildProfileCard(l10n.registrationID, registrationNumber ?? l10n.generating, Icons.badge, null, readOnly: true),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // App Settings Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.appSettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildProfileCard(
                    l10n.language,
                    _languageOptions[selectedLanguage] ?? 'English',
                    Icons.language,
                    _changeLanguage
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.saveChanges,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.deleteAccount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
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
                label: l10n.map ?? 'Map',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history, size: 26),
                label: l10n.history ?? 'History',
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

  Widget _buildProfileCard(String title, String value, IconData icon, VoidCallback? onEdit, {bool readOnly = false}) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kMainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kMainColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value.isEmpty ? l10n.tapToAdd : value,
        style: TextStyle(
          fontSize: 16,
          color: value.isEmpty ? Colors.grey : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: onEdit != null && !readOnly
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.edit_outlined, color: kMainColor, size: 20),
            )
          : readOnly
              ? Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18)
              : null,
      onTap: onEdit != null && !readOnly ? onEdit : null,
    );
  }

  void _editPhone() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.phone, color: kMainColor, size: 24),
              const SizedBox(width: 8),
              Text(l10n.editPhoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: l10n.enterYourPhoneNumber,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted) setState(() {});
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/collector_home');
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
}