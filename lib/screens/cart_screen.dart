import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/cart_model.dart' show Cart, CartItem;
import 'package:fire_flutter/model/usermodel.dart';
import 'package:fire_flutter/screens/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fire_flutter/model/cart_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Declaring the gradient colors
  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "My Cart",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),

        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),

      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: Cart.notifier,

        builder: (context, cartItems, _) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Your cart is empty",

                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: cartItems.length,

                  itemBuilder: (context, index) {
                    final item = cartItems[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: theme.cardColor,

                        borderRadius: BorderRadius.circular(16),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Container(
                            height: 70,
                            width: 70,

                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: item.image.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),

                                    child: Image.asset(
                                      item.image,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.image,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  item.name,

                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,

                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Rs.${(item.price * item.quantity).toStringAsFixed(0)}",

                                  style: GoogleFonts.poppins(
                                    color: theme.textTheme.bodyMedium?.color,

                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Color.fromARGB(255, 167, 57, 57),
                                ),

                                onPressed: () => Cart.removeItem(item.name),
                              ),

                              Text(
                                '${item.quantity}',

                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,

                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Color.fromARGB(255, 16, 207, 73),
                                ),

                                onPressed: () => Cart.addItem(
                                  CartItem(
                                    name: item.name,
                                    price: item.price,
                                    image: item.image,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Summary Section
              Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: theme.cardColor,

                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),

                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            "Subtotal",

                            style: GoogleFonts.poppins(
                              color: theme.textTheme.bodyMedium?.color,

                              fontSize: 14,
                            ),
                          ),

                          Text(
                            "Rs.${Cart.subtotal.toStringAsFixed(0)}",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,

                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            "Delivery Fee",

                            style: GoogleFonts.poppins(
                              color: theme.textTheme.bodyMedium?.color,

                              fontSize: 14,
                            ),
                          ),

                          Text(
                            Cart.deliveryFee == 0
                                ? "Free"
                                : "Rs.${Cart.deliveryFee.toStringAsFixed(0)}",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,

                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        height: 24,
                        thickness: 1,
                        color: theme.dividerColor,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            "Total Amount",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,

                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),

                          Text(
                            "Rs.${Cart.total.toStringAsFixed(0)}",

                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,

                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Gradient Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final firebaseUser =
                                FirebaseAuth.instance.currentUser;

                            if (firebaseUser == null) return;

                            final doc = await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(firebaseUser.uid)
                                .get();

                            if (!context.mounted) return;

                            final user = UserModal.fromJson(doc.data()!);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(user: user),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets
                                .zero, // Important to allow gradient to fill edge-to-edge
                            backgroundColor:
                                Colors.transparent, // Clears default background
                            shadowColor: Colors
                                .transparent, // Clears default button shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_greenDark, _green],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                "Proceed to Checkout",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
