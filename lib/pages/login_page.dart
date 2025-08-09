import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tealink/constants/colors.dart';
import 'package:tealink/pages/option_page.dart';
import 'package:tealink/pages/user_registration_screen.dart';
import 'package:tealink/pages/users/admin_dashboard.dart';
import 'package:tealink/pages/users/collector_dashboard.dart';
import 'package:tealink/pages/users/customer_dashboard.dart';
import 'package:tealink/widgets/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email to reset password")),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send reset email: $e")),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user data found in Firestore")),
        );
        return;
      }

      final role = userDoc['role'] as String?;
      if (role != null && role.isNotEmpty) {
        await SessionManager.saveUserRole(role);
        _navigateBasedOnRole(role);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RoleSelectionPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid);

      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phone': userCredential.user!.phoneNumber ?? '',
          'role': '',
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RoleSelectionPage()),
        );
      } else {
        final role = doc['role'] as String?;
        if (role != null && role.isNotEmpty) {
          await SessionManager.saveUserRole(role);
          _navigateBasedOnRole(role);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RoleSelectionPage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  void _navigateBasedOnRole(String role) {
    if (role.toLowerCase() == 'customer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerDashboard()),
      );
    } 
   else if (role.toLowerCase() == 'admin') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()),
    );
  } 
  
  else if (role.toLowerCase() == 'collector') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CollectorDashboard()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RoleSelectionPage()),
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
          SizedBox(width: 85,),
           Text(
             "LOG IN",
           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
             ),
         ],
       ),
          
        
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              SizedBox(height: 130),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email', hintText: 'Email'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password'),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text("Forgot password ?",style: TextStyle(color: kBlack),),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: kWhite,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  ),
                  child: Text('Sign in',style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,),),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              Center(child: Text('You can connect with')),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/images/Google_Logo.jpg', height: 24),
                  label: Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhite,
                    foregroundColor:kBlack,
                    elevation: 5,
                  ),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account ?",style: TextStyle(color: kBlack),),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserRegistrationScreen()),
                        );
                      },
                      child: Text("Sign up here", style: TextStyle(color: Colors.green)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}