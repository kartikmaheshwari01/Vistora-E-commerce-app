import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final UserModal user;

  /// Called after a successful save so the parent can refresh its state
  final void Function(UserModal updatedUser)? onUpdated;

  const EditProfileScreen({super.key, required this.user, this.onUpdated});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? _uploadedImageUrl;
  String? _uploadedPublicId;
  bool _isUploadingImage = false;

  // ── Firebase ───────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current values
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _addressCtrl = TextEditingController(text: widget.user.address);
    _cityCtrl = TextEditingController(text: widget.user.city);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Optimized: Pick image and immediately push to Cloudinary backend
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _isUploadingImage = true;
      });

      // Upload to Cloudinary right away
      final imageData = await _uploadProfileImage(_imageFile!);

      if (mounted) {
        setState(() {
          _uploadedImageUrl = imageData['url'];
          _uploadedPublicId = imageData['publicId'];
          _isUploadingImage = false;
        });
        _snack('Image uploaded successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _imageFile = null; // Reset local preview if upload fails
        });
        _snack('Image upload failed: ${e.toString()}', isError: true);
      }
    }
  }

  Future<Map<String, dynamic>> _uploadProfileImage(File file) async {
    const cloudName = "dfxlblwrb";
    const uploadPreset = "flutter_uploadd";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (response.statusCode == 200) {
      return {"url": data['secure_url'], "publicId": data['public_id']};
    } else {
      throw Exception(data['error']['message'] ?? "Failed to upload image");
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Guard if user hits save before background image upload finishes
    if (_isUploadingImage) {
      _snack('Please wait for the image upload to complete.', isError: true);
      return;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _snack('Session expired. Please log in again.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_uploadedImageUrl != null) 'profilePic': _uploadedImageUrl,
        if (_uploadedPublicId != null) 'publicId': _uploadedPublicId,
      };

      // Update Firestore document
      await _firestore
          .collection('Users')
          .doc(firebaseUser.uid)
          .update(updatedData);

      // Build updated UserModal
      final updated = UserModal(
        id: widget.user.id,
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        age: widget.user.age,
        profilePic: _uploadedImageUrl ?? widget.user.profilePic,
      );

      if (!mounted) return;

      widget.onUpdated?.call(updated);
      _snack('Profile updated successfully!', isError: false);

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      _snack('Failed to update: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _snack(String msg, {required bool isError}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? theme.colorScheme.error : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Image Provider resolution logic
    ImageProvider? avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(_imageFile!);
    } else if (widget.user.profilePic != null &&
        widget.user.profilePic!.isNotEmpty) {
      avatarImage = NetworkImage(widget.user.profilePic!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_greenDark, _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar with Edit Icon Option ───────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: (_isSaving || _isUploadingImage) ? null : _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _green.withOpacity(0.15),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                widget.user.username.isNotEmpty
                                    ? widget.user.username[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: _greenDark,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: _greenDark,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Info ─────────────────────────────────────────────
              _card(
                theme: theme,
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                children: [
                  _field(
                    theme: theme,
                    ctrl: _usernameCtrl,
                    label: 'Username',
                    hint: 'Your display name',
                    icon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    theme: theme,
                    ctrl: _emailCtrl,
                    label: 'Email Address',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final regex = RegExp(
                        r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                      );
                      if (!regex.hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    theme: theme,
                    ctrl: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '03XX-XXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Shipping Address ──────────────────────────────────────────
              _card(
                theme: theme,
                title: 'Shipping Address',
                icon: Icons.local_shipping_outlined,
                children: [
                  _field(
                    theme: theme,
                    ctrl: _addressCtrl,
                    label: 'Street Address',
                    hint: 'House no., Street, Area',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    theme: theme,
                    ctrl: _cityCtrl,
                    label: 'City',
                    hint: 'e.g. Karachi',
                    icon: Icons.location_city_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Save Button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_greenDark, _green]),
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
                    onPressed: (_isSaving || _isUploadingImage) ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(
            theme.brightness == Brightness.dark ? 0.3 : 0.04,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 16, 207, 73), size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: theme.dividerColor.withOpacity(0.4), height: 1),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _field({
    required ThemeData theme,
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.hintColor,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        cursorColor: _green,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: theme.textTheme.bodyLarge?.color,
        ),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: theme.hintColor.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 16, 207, 73),
            size: 20,
          ),
          filled: true,
          fillColor: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : theme.hintColor.withOpacity(0.04),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _green.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _green.withOpacity(0.2), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _green, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.8),
          ),
          errorStyle: GoogleFonts.poppins(
            fontSize: 11,
            color: theme.colorScheme.error,
          ),
        ),
      ),
    ],
  );
}
