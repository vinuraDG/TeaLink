import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tealink/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tealink/pages/login_page.dart';
import 'package:tealink/pages/option_page.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

// No changes to imports


Future<void> _signUpWithEmail() async {
  if (_formKey.currentState!.validate()) {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This email is already registered.")),
        );
        return;
      }

      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'role': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Account created! Please login."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create account: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    UserCredential userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': userCredential.user!.displayName ?? '',
        'email': userCredential.user!.email ?? '',
        'phone': userCredential.user!.phoneNumber ?? '',
        'role': 'customer',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Signed up with Google successfully!")),
    );

    // Navigate directly to Role Selection Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RoleSelectionPage()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to sign in with Google: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: kWhite),
        backgroundColor: kMainColor,
        title: Row(
          children: [
            SizedBox(width: 85),
            Text("SIGN UP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kWhite)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Name', hintText: 'D.G.V.Deelaka'),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Phone No', hintText: '07X XXX XXXX'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Password'),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: rePasswordController,
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Re-Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signUpWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: kWhite,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: Text('Sign up', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),
                Divider(),
                Center(child: Text('You can connect with')),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/images/Google_Logo.jpg', height: 24),
                  label: Text('Sign Up with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhite,
                    foregroundColor: kBlack,
                    elevation: 3,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have account ? "),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signin'),
                      child: Text('Sign in', style: TextStyle(color: kMainColor)),
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