import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fire_flutter/model/usermodel.dart';

class Sign_Up extends StatefulWidget {
  Sign_Up({super.key});

  @override
  State<Sign_Up> createState() => _Sign_UpState();
}

class _Sign_UpState extends State<Sign_Up> {
  // ── Firebase ───────────────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static final Color _green = const Color.fromARGB(255, 76, 175, 80);
  static final Color _greenDark = Colors.green.shade700;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Sign-up logic (unchanged) ──────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final String uid = credential.user!.uid;

      UserModal user = UserModal(
        id: uid,
        username: nameController.text.trim(),
        email: emailController.text.trim(),
         age: ageController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
      );

      await _firestore.collection("Users").doc(uid).set(user.toJson());
      await credential.user!.sendEmailVerification();

      if (mounted) {
        _showSnack(
          'Verification email sent! Please check your inbox.',
          isError: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      final String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Please login.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message = 'Signup service is disabled. Contact admin.';
          break;
        case 'network-request-failed':
          message = 'No internet connection. Check your network.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Signup failed. Please try again.';
      }
      if (mounted) _showSnack(message, isError: true);
    } catch (e) {
      debugPrint('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade500 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _green,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Top brand area ───────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.30,
              child: _buildHeader(),
            ),

            // ── White card ───────────────────────────────────────────────────
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
                        // Heading
                        Text(
                          'Create Account',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _greenDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign up to start shopping with Vistora',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Fields ─────────────────────────────────────────
                        _buildField(
                          controller: nameController,
                          hint: 'Full Name',

                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            if (!_emailRegex.hasMatch(v))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(),
                        SizedBox(height: 30),

                        // ── Sign Up button ─────────────────────────────────
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
                                  color: _green.withOpacity(0.45),
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
                              onPressed: _isLoading ? null : _signUp,
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
                                      'Create Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Login redirect ─────────────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _greenDark,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _greenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
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

  // ── Header ────────────────────────────────────────────────────────────────
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
          // Logo circle
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic field ─────────────────────────────────────────────────────────
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
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      validator: validator,
      cursorColor: Colors.green.shade500,
      decoration: _inputDecoration(hint: hint, prefixIcon: icon),
    );
  }

  // ── Password field with working eye toggle ────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration:
          _inputDecoration(
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(_obscurePassword),
                  color: Colors.green.shade400,
                  size: 22,
                ),
              ),
            ),
          ),
    );
  }

  // ── Confirm Password Field ───────────────────────────────────────────────
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPasswordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Please confirm your password';
        }

        if (v != passwordController.text.trim()) {
          return 'Passwords do not match';
        }

        return null;
      },
      decoration:
          _inputDecoration(
            hint: 'Confirm Password',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(_obscurePassword),
                  color: Colors.green.shade400,
                  size: 22,
                ),
              ),
            ),
          ),
    );
  }

  // ── Shared input decoration ───────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(prefixIcon, color: Colors.green.shade500, size: 20),
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
}
