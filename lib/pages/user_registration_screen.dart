import 'package:TeaLink/l10n/app_localizations.dart';
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

class _UserRegistrationScreenState extends State<UserRegistrationScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final registrationNumberController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    registrationNumberController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: kWhite),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // ---------------------------
  // EMAIL/PASSWORD SIGN UP
  // ---------------------------
  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final regNo = registrationNumberController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _postSignUpTransaction(
        userCred: userCred,
        name: name,
        registrationNumber: regNo,
        phone: phone,
        email: email,
        role: '',
      );

      _showSnackBar(
        "Account created successfully! Welcome to TeaLink!",
        kMainColor!,
        Icons.check_circle,
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    } catch (e) {
      await _safeDeleteCurrentUser();
      
      String errorMessage = "Failed to create account. Please try again.";
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = "An account with this email already exists.";
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "Password is too weak. Please choose a stronger password.";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "Please enter a valid email address.";
      } else if (e.toString().contains('already registered')) {
        errorMessage = "This email is already registered.";
      } else if (e.toString().contains('registration number')) {
        errorMessage = "This registration number is already in use.";
      }
      
      _showSnackBar(errorMessage, Colors.red[600]!, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------
  // GOOGLE SIGN IN / UP
  // ---------------------------
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      await _postSignUpTransaction(
        userCred: userCred,
        name: userCred.user?.displayName ?? '',
        registrationNumber: '',
        phone: userCred.user?.phoneNumber ?? '',
        email: userCred.user?.email ?? '',
        role: '',
      );

      _showSnackBar(
        "Signed in with Google successfully!",
        Colors.green[600]!,
        Icons.check_circle,
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    } catch (e) {
      await _safeDeleteCurrentUser();
      _showSnackBar(
        "Failed to sign in with Google. Please try again.",
        Colors.red[600]!,
        Icons.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

    final emailKey = email.trim().toLowerCase();
    final emailRef = db.collection('unique_emails').doc(emailKey);

    final hasReg = registrationNumber.trim().isNotEmpty;
    final regKey = registrationNumber.trim();
    final regRef = hasReg ? db.collection('unique_reg_nos').doc(regKey) : null;

    try {
      await db.runTransaction((tx) async {
        final emailSnap = await tx.get(emailRef);
        if (emailSnap.exists) {
          throw Exception('This email is already registered.');
        }

        if (regRef != null) {
          final regSnap = await tx.get(regRef);
          if (regSnap.exists) {
            throw Exception('This registration number is already used.');
          }
        }

        tx.set(emailRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        if (regRef != null) {
          tx.set(regRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
        }

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
      await _safeDeleteCurrentUser();
      rethrow;
    }
  }

  Future<void> _safeDeleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (_) {}
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onVisibilityToggle,
    bool isPasswordVisible = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon, color: kMainColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: kGrey,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: kMainColor!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kMainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kWhite),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OnboardingScreen()),
            );
          },
        ),
        title: Text(
          loc.signUpTitle,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: kWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, size: 50, color: kMainColor),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            loc.joinTeaLink,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.createAccount,
                            style: TextStyle(fontSize: 16, color: kGrey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.personalInfo,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kGrey),
                          ),
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: nameController,
                            label: loc.fullName,
                            hint: '',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => (v == null || v.isEmpty) ? loc.fullName : null,
                          ),
                          
                          _buildTextField(
                            controller: registrationNumberController,
                            label: loc.regNo,
                            hint: '',
                            prefixIcon: Icons.badge_outlined,
                          ),
                          
                          _buildTextField(
                            controller: phoneController,
                            label: loc.phoneNumber,
                            hint: '07X XXX XXXX',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return loc.phoneNumber;
                              }
                              if (v.length < 10) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          Text(
                            loc.accountDetails,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kGrey),
                          ),
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            controller: emailController,
                            label: loc.emailAddress,
                            hint: 'your.email@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          _buildTextField(
                            controller: passwordController,
                            label: loc.password,
                            hint: 'At least 6 characters',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            isPassword: true,
                            isPasswordVisible: _isPasswordVisible,
                            onVisibilityToggle: () {
                              setState(() => _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          
                          _buildTextField(
                            controller: rePasswordController,
                            label: loc.confirmPassword,
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isRePasswordVisible,
                            isPassword: true,
                            isPasswordVisible: _isRePasswordVisible,
                            onVisibilityToggle: () {
                              setState(() => _isRePasswordVisible = !_isRePasswordVisible);
                            },
                          ),
                          
                          const SizedBox(height: 10),
                          
                          Container(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUpWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMainColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                                    )
                                  : Text(
                                      loc.createAccountButton,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kWhite),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: kGrey, fontWeight: FontWeight.w500)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Image.asset('assets/images/Google_Logo.jpg', height: 24),
                        label: Text(
                          loc.googleSignUp,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          backgroundColor: kWhite,
                          foregroundColor: kGrey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loc.alreadyHaveAccount, style: TextStyle(color: kGrey, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signin'),
                            child: Text(
                              loc.signInHere,
                              style: TextStyle(color: kMainColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
