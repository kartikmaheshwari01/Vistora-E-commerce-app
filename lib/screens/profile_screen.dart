import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/screens/editprofile_screen.dart';
import 'package:fire_flutter/screens/ordershistory_screen.dart';
import 'package:fire_flutter/screens/setttings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:fire_flutter/model/cart_model.dart';
import 'package:fire_flutter/model/wishlist_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModal user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final Color _green = const Color.fromARGB(255, 76, 175, 80);
  static final Color _darkGreen = const Color(0xFF388E3C);

  UserModal? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    // Start with passed user so screen renders immediately
    _currentUser = widget.user;
    // Then fetch fresh from Firestore to pick up saved profilePic
    _loadFreshUser();
  }

  /// Fetch the latest user document from Firestore every time the
  /// profile screen opens — guarantees profilePic is always up to date.
  Future<void> _loadFreshUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(firebaseUser.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentUser = UserModal.fromJson(doc.data()!);
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  int get _cartCount => Cart.items.length;
  int get _wishlistCount => Wishlist.items.length;

  @override
  Widget build(BuildContext context) {
    // FIX: Safely fallback to widget.user if _currentUser is null
    final userProfile = _currentUser ?? widget.user;

    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PROFILE HEADER ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_darkGreen, _green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Row(
                children: [
                  // Avatar - Safe via userProfile with cache busting query parameter
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      image:
                          userProfile.profilePic != null &&
                              userProfile.profilePic!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(userProfile.profilePic!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        userProfile.profilePic != null &&
                            userProfile.profilePic!.isNotEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            userProfile.username.isNotEmpty
                                ? userProfile.username[0].toUpperCase()
                                : "U",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                  ),
                  const SizedBox(width: 18),
                  // Name + email - Safe via userProfile
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.username,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                userProfile.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QUICK STATS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statCard(
                    context: context,
                    icon: Icons.shopping_cart_outlined,
                    label: "Cart",
                    value: "$_cartCount",
                    color: _green,
                  ),
                  const SizedBox(width: 14),
                  _statCard(
                    context: context,
                    icon: Icons.favorite_border_rounded,
                    label: "Wishlist",
                    value: "$_wishlistCount",
                    color: Colors.pinkAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Account",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── EDIT PROFILE TILE ──
            _menuTile(
              context: context,
              icon: Icons.person_outline_rounded,
              label: "Edit Profile",
              onTap: () async {
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) return;

                final doc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(firebaseUser.uid)
                    .get();

                if (!context.mounted) return;

                UserModal freshUser = UserModal.fromJson(doc.data()!);

                final updated = await Navigator.push<UserModal>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      user: freshUser,
                      onUpdated: (updatedUser) {
                        setState(() => _currentUser = updatedUser);
                      },
                    ),
                  ),
                );

                if (updated != null && context.mounted) {
                  setState(() => _currentUser = updated);
                }
              },
            ),

            _menuTile(
              context: context,
              icon: Icons.history_rounded,
              label: "Order History",
              onTap: () async {
                final firebaseUser = FirebaseAuth.instance.currentUser;
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
                    builder: (_) => OrderHistoryScreen(user: user),
                  ),
                );
              },
            ),

            _menuTile(
              context: context,
              icon: Icons.notifications_outlined,
              label: "Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const SizedBox(height: 28),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Log Out",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ──
  void _confirmLogout(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Log Out",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: GoogleFonts.poppins(fontSize: 14, color: subColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Cart.clear();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(
              "Log Out",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat card helper ──
  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu tile helper ──
  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 76, 175, 80),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
