import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/screens/ordershistory_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fire_flutter/model/cart_model.dart';
import 'package:fire_flutter/model/order_model.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutScreen extends StatefulWidget {
  final UserModal user;

  const CheckoutScreen({super.key, required this.user});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ── Firebase ──────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _isPlacing = false;

  // ── Theme ─────────────────────────────────────────────────────────────────
  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;
  static const Color _dark = Color(0xFF1E1E24);

  @override
  void initState() {
    super.initState();
    // Pre-fill name from logged-in user
    _nameCtrl.text = widget.user.username;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── Cart summary helpers ──────────────────────────────────────────────────
  List<CartItem> get _cartItems => Cart.items;
  double get _subtotal => Cart.total;
  double get _delivery => _subtotal > 2000 ? 0 : 149;
  double get _grandTotal => _subtotal + _delivery;

  // ── Place order ───────────────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cartItems.isEmpty) {
      _snack('Your cart is empty.', isError: true);
      return;
    }

    // Guard: user must be authenticated
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _snack('Session expired. Please log in again.', isError: true);
      return;
    }
    final String uid = currentUser.uid;

    setState(() => _isPlacing = true);

    try {
      // Build order items from cart
      final orderItems = _cartItems
          .map(
            (ci) => OrderItem(
              name: ci.name,
              price: ci.price,
              image: ci.image,
              quantity: ci.quantity,
            ),
          )
          .toList();

      final order = OrderModel(
        id: '',
        userId: uid,
        userName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        items: orderItems,
        subtotal: _subtotal,
        deliveryFee: _delivery,
        grandTotal: _grandTotal,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        paymentMethod: 'Cash on Delivery',
      );

      // Save to Firestore under users/{uid}/orders and global orders collection
      final batch = _firestore.batch();

      final globalRef = _firestore.collection('orders').doc();
      final userRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(globalRef.id);

      batch.set(globalRef, order.toJson());
      batch.set(userRef, order.toJson());
      await batch.commit();

      // Clear cart after successful save
      Cart.clear();

      if (!mounted) return;
      _showSuccessSheet(globalRef.id);
    } catch (e) {
      _snack('Failed to place order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  // ── Success bottom sheet ──────────────────────────────────────────────────
  void _showSuccessSheet(String orderId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: _green, size: 52),
            ),
            const SizedBox(height: 18),
            Text(
              'Order Placed!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been received.\nWe\'ll deliver it to your doorstep.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).dividerColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Order ID chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, color: _green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Order ID: ${orderId.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _greenDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // COD reminder
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pay Rs.${_grandTotal.toStringAsFixed(0)} in cash when your order arrives.',
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderHistoryScreen(user: widget.user),
                        ),
                      );
                    },
                    child: Text(
                      'My Orders',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // sheet
                      Navigator.pop(context); // checkout
                      Navigator.pop(context); // cart → home
                    },
                    child: Text(
                      'Continue Shopping',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Theme.of(context).cardColor),
        ),
        backgroundColor: isError ? Colors.red.shade500 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
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
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).cardColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Payment method badge ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.money_rounded,
                        color: Theme.of(context).cardColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                        Text(
                          'Pay when your order arrives',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).cardColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: _green, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Delivery info card ───────────────────────────────────────
              _card(
                title: 'Delivery Information',
                icon: Icons.local_shipping_outlined,
                children: [
                  _field(
                    ctrl: _nameCtrl,
                    label: 'Full Name',
                    hint: 'e.g. Ali Raza',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    ctrl: _phoneCtrl,
                    label: 'Phone Number',
                    hint: '03XX-XXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\-\+]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Phone is required';
                      if (v.trim().length < 10)
                        return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    ctrl: _addressCtrl,
                    label: 'Street Address',
                    hint: 'House no., Street, Area',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    ctrl: _cityCtrl,
                    label: 'City',
                    hint: 'e.g. Karachi',
                    icon: Icons.location_city_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'City is required'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Order summary card ───────────────────────────────────────
              _card(
                title: 'Order Summary',
                icon: Icons.receipt_long_outlined,
                children: [
                  if (_cartItems.isEmpty)
                    Center(
                      child: Text(
                        'Cart is empty',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).dividerColor,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else ...[
                    ..._cartItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: Theme.of(context).dividerColor,
                                child: item.image.startsWith('http')
                                    ? Image.network(
                                        item.image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_outlined,
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      )
                                    : Image.asset(
                                        item.image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_outlined,
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item.name} × ${item.quantity}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF1E1E24),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Rs.${(item.price * item.quantity).toStringAsFixed(0)}',
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
                    Divider(color: Theme.of(context).dividerColor, height: 20),
                    _summaryRow(
                      'Subtotal',
                      'Rs.${_subtotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'Delivery',
                      _delivery == 0
                          ? 'FREE'
                          : 'Rs.${_delivery.toStringAsFixed(0)}',
                      valueColor: _delivery == 0 ? Colors.green.shade600 : null,
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 20),
                    _summaryRow(
                      'Total (COD)',
                      'Rs.${_grandTotal.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                    if (_delivery == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              color: Colors.green.shade500,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Free delivery on orders above Rs.2,000!',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 26),

              // ── Place order button ───────────────────────────────────────
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
                    onPressed: _isPlacing ? null : _placeOrder,
                    child: _isPlacing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).cardColor,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).cardColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Place Order  •  Rs.${_grandTotal.toStringAsFixed(0)}',
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
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: Theme.of(context).dividerColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Safe & Secure Checkout',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
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
            Icon(icon, color: _green, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: Colors.grey.shade100, height: 1),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        cursorColor: _green,
        inputFormatters: inputFormatters,
        style: GoogleFonts.poppins(fontSize: 14, color: _dark),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon, color: _green, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade100, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _green, width: 1.8),
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

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: isBold ? 14 : 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isBold
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Colors.grey.shade600,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: isBold ? 16 : 13,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color:
              valueColor ??
              (isBold
                  ? _greenDark
                  : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    ],
  );
}
