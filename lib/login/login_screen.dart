import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/cart_model.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:fire_flutter/model/wishlist_model.dart';
import 'package:fire_flutter/screens/main_screen.dart';
import 'package:fire_flutter/signup/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Firebase ───────────────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController resetEmailController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // ── Theme Colors ───────────────────────────────────────────────────────────
  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      setState(() {
        _rememberMe = true;
        emailController.text = prefs.getString('saved_email') ?? '';
        passwordController.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      await Cart.init(uid);
      await Wishlist.init(uid);

      await _saveRememberMe();

      DocumentSnapshot data = await _firestore
          .collection("Users")
          .doc(uid)
          .get();

      UserModal loggedUser = UserModal(
        id: uid,
        username: data["username"],
        email: data["email"],
        age: data["age"],
        phone: data["phone"],
        address: data["address"],
        city: data["city"],
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(user: loggedUser)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Invalid login credentials.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email.';
          break;

        case 'network-request-failed':
          message = 'No internet connection.';
          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      _showSnack(message, isError: true);
    } catch (e) {
      _showSnack('Something went wrong: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────
  Future<void> _resetPassword(String email) async {
    if (email.trim().isEmpty || !_emailRegex.hasMatch(email.trim())) {
      _showSnack('Enter a valid email address.', isError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      if (mounted) {
        Navigator.pop(context);

        _showSnack('Password reset link sent successfully.', isError: false);
      }
    } catch (e) {
      _showSnack('Failed to send reset link.', isError: true);
    }
  }

  // ── SnackBar ───────────────────────────────────────────────────────────────
  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade500 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _green,
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.30,
              child: _buildHeader(),
            ),

            // White Container
            Positioned(
              top: size.height * 0.26,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _greenDark,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Login to continue shopping with Vistora',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Email
                        _buildField(
                          controller: emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Email is required';
                            }

                            if (!_emailRegex.hasMatch(v)) {
                              return 'Enter valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _buildPasswordField(),

                        // Remember Me + Forgot Password row
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Remember Me checkbox
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(
                                            () => _rememberMe = val ?? false),
                                        activeColor: _green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey.shade400),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Forgot Password
                              GestureDetector(
                                onTap: _showForgotPasswordModal,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _greenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade700,
                                  Colors.green.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign Up
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Sign_Up(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _greenDark,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                'V',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'VISTORA',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Your Shopping Destination',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Fields ─────────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: _green,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: _inputDecoration(hint: hint, prefixIcon: icon),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Password is required';
        }
        return null;
      },
      cursorColor: _green,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration:
          _inputDecoration(
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.green.shade400,
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(prefixIcon, color: Colors.green.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade100, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade500, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
    );
  }

  // ── Forgot Password Modal ──────────────────────────────────────────────────
  void _showForgotPasswordModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Reset Password",
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: _greenDark,
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email address to receive reset link.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: resetEmailController,
                decoration: _inputDecoration(
                  hint: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 20,
            left: 20,
            right: 20,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    _resetPassword(resetEmailController.text);
                  },
                  child: Text(
                    'Send Link',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}