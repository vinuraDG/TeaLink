import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:TeaLink/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TeaLink/pages/onboarding_screen.dart';
import 'package:TeaLink/pages/option_page.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final registrationNumberController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  // ---------------------------
  // EMAIL/PASSWORD SIGN UP
  // ---------------------------
  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final regNo = registrationNumberController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    try {
      // 1) Create Auth user first
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) Do atomic uniqueness + profile write in a transaction
      await _postSignUpTransaction(
        userCred: userCred,
        name: name,
        registrationNumber: regNo,
        phone: phone,
        email: email,
        role: '',
      );

      // 3) Done
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Account created successfully!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    } catch (e) {
      // If something failed, try to clean up the just-created Auth user
      await _safeDeleteCurrentUser();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to create account: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ---------------------------
  // GOOGLE SIGN IN / UP
  // ---------------------------
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      // Use same post-signup flow (regNo empty by default)
      await _postSignUpTransaction(
        userCred: userCred,
        name: userCred.user?.displayName ?? '',
        registrationNumber: '',
        phone: userCred.user?.phoneNumber ?? '',
        email: userCred.user?.email ?? '',
        role: 'customer',
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Signed in with Google successfully!"),
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    } catch (e) {
      await _safeDeleteCurrentUser();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in with Google: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ---------------------------
  // SHARED: ATOMIC POST-SIGNUP
  // ---------------------------
  Future<void> _postSignUpTransaction({
    required UserCredential userCred,
    required String name,
    required String registrationNumber,
    required String phone,
    required String email,
    required String role,
  }) async {
    final uid = userCred.user!.uid;
    final db = FirebaseFirestore.instance;

    final usersRef = db.collection('users').doc(uid);

    // “Index” docs for uniqueness (doc IDs)
    final emailKey = email.trim().toLowerCase();
    final emailRef = db.collection('unique_emails').doc(emailKey);

    final hasReg = registrationNumber.trim().isNotEmpty;
    final regKey = registrationNumber.trim();
    final regRef = hasReg ? db.collection('unique_reg_nos').doc(regKey) : null;

    try {
      await db.runTransaction((tx) async {
        // Check unique email
        final emailSnap = await tx.get(emailRef);
        if (emailSnap.exists) {
          throw Exception('This email is already registered.');
        }

        // Check unique reg no (if provided)
        if (regRef != null) {
          final regSnap = await tx.get(regRef);
          if (regSnap.exists) {
            throw Exception('This registration number is already used.');
          }
        }

        // Reserve uniqueness (create the index docs)
        tx.set(emailRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (regRef != null) {
          tx.set(regRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Create the user profile
        tx.set(usersRef, {
          'name': name,
          'registrationNumber': registrationNumber,
          'phone': phone,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // If the transaction fails, delete the Auth user so we roll back fully.
      await _safeDeleteCurrentUser();
      rethrow;
    }
  }

  // Delete the current user if possible (recently created/reauthenticated)
  Future<void> _safeDeleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (_) {
      // If delete needs recent login or already gone, ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: kWhite),
        backgroundColor: kMainColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => onboardingScreen()),
            );
          },
        ),
        title: const Row(
          children: [
            SizedBox(width: 85),
            Text(
              "SIGN UP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhite),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                    hintText: 'D.G.V.Deelaka',
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: registrationNumberController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Registration Number',
                    hintText: 'REG123456',
                  ),
                  // Optional field; make required if your app needs it
                  validator: (v) => null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Phone No',
                    hintText: '07X XXX XXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  validator: (v) =>
                      (v != null && v.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: rePasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Re-Password',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signUpWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: const Text('Sign up',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Center(child: Text('You can connect with')),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/images/Google_Logo.jpg', height: 24),
                  label: const Text('Sign Up with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhite,
                    foregroundColor: kBlack,
                    elevation: 3,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have account ? "),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signin'),
                      child: const Text('Sign in', style: TextStyle(color: kMainColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
