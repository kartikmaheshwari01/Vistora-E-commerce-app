import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  // ── Firebase ───────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  // ── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _originalCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController(text: '4.5');

  // ── State ──────────────────────────────────────────────────────────────────
  File? _imageFile;
  String _selectedCategory = 'Clothes';
  bool _isSpecialOffer = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;
  static const Color _dark = Color(0xFF1E1E24);

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Clothes', 'icon': Icons.checkroom_outlined},
    {'name': 'Electronics', 'icon': Icons.devices_outlined},
    {'name': 'Health', 'icon': Icons.favorite_border},
    {'name': 'Furniture', 'icon': Icons.chair_outlined},
    {'name': 'Kitchen', 'icon': Icons.kitchen_outlined},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _originalCtrl.dispose();
    _discountCtrl.dispose();
    _descCtrl.dispose();
    _ratingCtrl.dispose();
    super.dispose();
  }

  // ── Pick image from gallery ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // ── Upload image to Firebase Storage ───────────────────────────────────────
  // Future<String> _uploadImage(File file) async {
  //   final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
  //   final ref = _storage.ref().child(fileName);

  //   final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

  //   // Track upload progress
  //   task.snapshotEvents.listen((snap) {
  //     if (snap.totalBytes > 0) {
  //       setState(() {
  //         _uploadProgress = snap.bytesTransferred / snap.totalBytes;
  //         _uploadStatus =
  //             'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%';
  //       });
  //     }
  //   });

  //   final snapshot = await task;
  //   return await snapshot.ref.getDownloadURL();
  // }
  Future<Map<String, dynamic>> _uploadImage(File file) async {
    const cloudName = "dfxlblwrb";
    const uploadPreset = "flutter_uploadd";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    setState(() {
      _uploadStatus = "Uploading image...";
      _uploadProgress = 0.3;
    });

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (response.statusCode == 200) {
      return {
        "url": data['secure_url'],
        "publicId": data['public_id'], // 🔥 IMPORTANT for delete
      };
    } else {
      throw Exception(data['error']['message']);
    }
  }

  Future<void> deleteFromCloudinary(String publicId) async {
    const cloudName = "dfxlblwrb";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/delete_by_token",
    );

    // ⚠️ We are NOT using API secret (client-safe version is limited)
    await http.post(url, body: {"public_id": publicId});
  }

  // ── Save product to Firestore ───────────────────────────────────────────────
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _snack('Please select a product image', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Preparing upload...';
      _uploadProgress = 0;
    });

    try {
      // 1. Upload image → get URL
      setState(() => _uploadStatus = 'Uploading image...');
      final imageData = await _uploadImage(_imageFile!);
      // 2. Save product document
      setState(() => _uploadStatus = 'Saving product...');
      await _firestore.collection('products').add({
        'name': _nameCtrl.text.trim(),
        'price': 'Rs.${_priceCtrl.text.trim()}',
        'originalPrice': _originalCtrl.text.trim().isEmpty
            ? ''
            : 'Rs.${_originalCtrl.text.trim()}',
        'discount': _discountCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'rating': double.tryParse(_ratingCtrl.text.trim()) ?? 4.5,

        'img': imageData['url'],
        'publicId': imageData['publicId'], // 🔥 STORE THIS

        'isSpecialOffer': _isSpecialOffer,
        'discountText': _isSpecialOffer
            ? (_discountCtrl.text.trim().isEmpty
                  ? ''
                  : '${_discountCtrl.text.trim()} off')
            : '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack('Product added successfully!', isError: false);
      _clearForm();
    } catch (e) {
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
      }
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _priceCtrl.clear();
    _originalCtrl.clear();
    _discountCtrl.clear();
    _descCtrl.clear();
    _ratingCtrl.text = '4.5';
    setState(() {
      _imageFile = null;
      _selectedCategory = 'Clothes';
      _isSpecialOffer = false;
    });
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Theme.of(context).cardColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).cardColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade500 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).cardColor,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Product',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).cardColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image picker ────────────────────────────────────────
                  _card(
                    title: 'Product Image',
                    icon: Icons.image_outlined,
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _imageFile != null
                                  ? _green
                                  : Colors.green.shade200,
                              width: _imageFile != null ? 2 : 1.5,
                              style: _imageFile != null
                                  ? BorderStyle.solid
                                  : BorderStyle.solid,
                            ),
                          ),
                          child: _imageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        _imageFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Change button
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Theme.of(
                                                  context,
                                                ).cardColor,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Change',
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(
                                                    context,
                                                  ).cardColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: _green,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap to select from gallery',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _greenDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG, PNG • Max 5MB',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Basic info ──────────────────────────────────────────
                  _card(
                    title: 'Product Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _field(
                        ctrl: _nameCtrl,
                        label: 'Product Name',
                        hint: 'e.g. Slim Fit Jeans',
                        icon: Icons.shopping_bag_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        ctrl: _descCtrl,
                        label: 'Description',
                        hint: 'Describe the product in detail...',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description is required'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Pricing ─────────────────────────────────────────────
                  _card(
                    title: 'Pricing',
                    icon: Icons.money,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              ctrl: _priceCtrl,
                              label: 'Sale Price',
                              hint: '899',
                              icon: Icons.price_change_outlined,
                              keyboard: TextInputType.number,
                              prefix: 'Rs.',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(v.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              ctrl: _originalCtrl,
                              label: 'Original Price',
                              hint: '1499  (optional)',
                              icon: Icons.money_off_outlined,
                              keyboard: TextInputType.number,
                              prefix: 'Rs.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              ctrl: _discountCtrl,
                              label: 'Discount %',
                              hint: '40%  (optional)',
                              icon: Icons.percent_rounded,
                              keyboard: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              ctrl: _ratingCtrl,
                              label: 'Rating (0-5)',
                              hint: '4.5',
                              icon: Icons.star_outline_rounded,
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final r = double.tryParse(v.trim());
                                if (r == null || r < 0 || r > 5) {
                                  return '0 to 5';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Category ────────────────────────────────────────────
                  _card(
                    title: 'Category',
                    icon: Icons.category_outlined,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((cat) {
                          final selected = _selectedCategory == cat['name'];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedCategory = cat['name'] as String,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _green
                                    : Theme.of(context).dividerColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? _green
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    size: 16,
                                    color: selected
                                        ? Theme.of(context).cardColor
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Theme.of(context).cardColor
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Special offer toggle ────────────────────────────────
                  _card(
                    title: 'Special Offer',
                    icon: Icons.local_offer_outlined,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.star_outlined,
                              color: Colors.orange.shade400,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as Special Offer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _dark,
                                  ),
                                ),
                                Text(
                                  'Shows in the Special Offers banner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSpecialOffer,
                            activeColor: _green,
                            onChanged: (v) =>
                                setState(() => _isSpecialOffer = v),
                          ),
                        ],
                      ),
                      if (_isSpecialOffer) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This product will appear in the '
                                  'Special Offers carousel on the home screen.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Submit ──────────────────────────────────────────────
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
                        onPressed: _isUploading ? null : _saveProduct,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: Theme.of(context).cardColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add Product to Store',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).cardColor,
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

          // ── Upload overlay ────────────────────────────────────────────
          if (_isUploading)
            Container(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: _green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading Product',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uploadStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_green),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _uploadProgress > 0
                            ? '${(_uploadProgress * 100).toStringAsFixed(0)}%'
                            : 'Please wait...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(icon, color: Color.fromARGB(255, 16, 207, 73), size: 18),

              const SizedBox(width: 8),

              Text(
                title,

                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(color: theme.dividerColor, height: 1),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          cursorColor: theme.colorScheme.primary,

          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color,
          ),

          validator: validator,

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),

            prefixIcon: Icon(
              icon,
              color: Color.fromARGB(255, 16, 207, 73),
              size: 20,
            ),

            prefixText: prefix,

            prefixStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),

            filled: true,
            fillColor: theme.scaffoldBackgroundColor,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide(color: theme.dividerColor),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide(color: theme.dividerColor, width: 1.2),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.8,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: Colors.red, width: 1.8),
            ),

            errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
