import 'package:fire_flutter/screens/admin_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fire_flutter/screens/admin_add_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Drop this widget anywhere you want the admin FAB to appear.
/// It automatically hides itself for non-admin users.
class AdminFab extends StatelessWidget {
  const AdminFab({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    // Not an admin → render nothing
    if (!AdminConfig.isAdmin(email)) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminAddProductScreen(),
        ),
      ),
      backgroundColor: Colors.green.shade600,
      elevation: 6,
      icon:  Icon(Icons.add_circle_outline_rounded,
          color: Theme.of(context).cardColor, size: 22),
      label: Text(
        'Add Product',
        style: GoogleFonts.poppins(
          color: Theme.of(context).cardColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}