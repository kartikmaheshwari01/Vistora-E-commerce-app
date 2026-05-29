import 'package:fire_flutter/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Color _green = Colors.green.shade500;
  static final Color _greenDark = Colors.green.shade700;
  static const Color _dark = Color(0xFF1E1E24);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.darkMode;

    // ── Adaptive colours for dark/light using Theme ─────────────────────────
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF9FAFC);
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark
        ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
        : _dark;
    final subColor = isDark
        ? (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade400)
        : Colors.grey.shade600;
    final divColor = isDark
        ? Theme.of(context).dividerColor
        : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
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
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── APPEARANCE ────────────────────────────────────────────────────
          _sectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            cardColor: cardColor,
            divColor: divColor,
            textColor: textColor,
            children: [
              // Dark mode
              _switchTile(
                icon: Icons.dark_mode_outlined,
                iconBg: Colors.indigo.shade50,
                iconColor: Colors.indigo.shade400,
                title: 'Dark Mode',
                subtitle: 'Switch to dark theme',
                value: settings.darkMode,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setDarkMode(v),
              ),
              _divider(divColor),

              // Font size
              _dropdownTile(
                icon: Icons.text_fields_rounded,
                iconBg: Colors.teal.shade50,
                iconColor: Colors.teal.shade400,
                title: 'Text Size',
                subtitle: 'Adjust reading comfort',
                options: const ['Small', 'Medium', 'Large'],
                selected: settings.fontSizeIndex,
                textColor: textColor,
                subColor: subColor,
                cardColor: cardColor,
                onChanged: (i) =>
                    context.read<SettingsProvider>().setFontSize(i),
              ),
              _divider(divColor),

              // Language
              _dropdownTile(
                icon: Icons.language_outlined,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue.shade400,
                title: 'Language',
                subtitle: settings.language,
                options: const ['English', 'Urdu'],
                selected: settings.language == 'English' ? 0 : 1,
                textColor: textColor,
                subColor: subColor,
                cardColor: cardColor,
                onChanged: (i) => context.read<SettingsProvider>().setLanguage(
                  i == 0 ? 'English' : 'Urdu',
                ),
              ),
              _divider(divColor),

              // Currency
              _dropdownTile(
                icon: Icons.currency_exchange_outlined,
                iconBg: Colors.green.shade50,
                iconColor: Colors.green.shade500,
                title: 'Currency',
                subtitle: settings.currency,
                options: const ['Rs', 'USD'],
                selected: settings.currency == 'Rs' ? 0 : 1,
                textColor: textColor,
                subColor: subColor,
                cardColor: cardColor,
                onChanged: (i) => context.read<SettingsProvider>().setCurrency(
                  i == 0 ? 'Rs' : 'USD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── NOTIFICATIONS ─────────────────────────────────────────────────
          _sectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            cardColor: cardColor,
            divColor: divColor,
            textColor: textColor,
            children: [
              // Master toggle
              _switchTile(
                icon: Icons.notifications_active_outlined,
                iconBg: Colors.orange.shade50,
                iconColor: Colors.orange.shade400,
                title: 'Push Notifications',
                subtitle: 'Enable all notifications',
                value: settings.notifications,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setNotifications(v),
              ),
              _divider(divColor),

              // Order updates — disabled when master is off
              _switchTile(
                icon: Icons.local_shipping_outlined,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue.shade400,
                title: 'Order Updates',
                subtitle: 'Shipping & delivery alerts',
                value: settings.orderUpdates,
                textColor: textColor,
                subColor: subColor,
                enabled: settings.notifications,
                onChanged: settings.notifications
                    ? (v) => context.read<SettingsProvider>().setOrderUpdates(v)
                    : null,
              ),
              _divider(divColor),

              // Promo alerts
              _switchTile(
                icon: Icons.local_offer_outlined,
                iconBg: Colors.pink.shade50,
                iconColor: Colors.pink.shade400,
                title: 'Promo & Offers',
                subtitle: 'Deals, discounts & flash sales',
                value: settings.promoAlerts,
                textColor: textColor,
                subColor: subColor,
                enabled: settings.notifications,
                onChanged: settings.notifications
                    ? (v) => context.read<SettingsProvider>().setPromoAlerts(v)
                    : null,
              ),
              _divider(divColor),

              // Email notifications
              _switchTile(
                icon: Icons.email_outlined,
                iconBg: Colors.purple.shade50,
                iconColor: Colors.purple.shade400,
                title: 'Email Notifications',
                subtitle: 'Order receipts & account updates',
                value: settings.emailNotifs,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setEmailNotifs(v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── PRIVACY & SECURITY ────────────────────────────────────────────
          _sectionCard(
            title: 'Privacy & Security',
            icon: Icons.security_outlined,
            cardColor: cardColor,
            divColor: divColor,
            textColor: textColor,
            children: [
              // Biometric
              _switchTile(
                icon: Icons.fingerprint_rounded,
                iconBg: Colors.teal.shade50,
                iconColor: Colors.teal.shade500,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face ID',
                value: settings.biometric,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setBiometric(v),
              ),
              _divider(divColor),

              // Save address
              _switchTile(
                icon: Icons.save_outlined,
                iconBg: Colors.green.shade50,
                iconColor: Colors.green.shade500,
                title: 'Save Delivery Address',
                subtitle: 'Auto-fill at checkout',
                value: settings.saveAddress,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setSaveAddress(v),
              ),
              _divider(divColor),

              // Change password — nav tile
              _navTile(
                icon: Icons.lock_outline_rounded,
                iconBg: Colors.red.shade50,
                iconColor: Colors.red.shade400,
                title: 'Change Password',
                subtitle: 'Update your account password',
                textColor: textColor,
                subColor: subColor,
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── PREFERENCES ───────────────────────────────────────────────────
          _sectionCard(
            title: 'Preferences',
            icon: Icons.tune_rounded,
            cardColor: cardColor,
            divColor: divColor,
            textColor: textColor,
            children: [
              // Newsletter
              _switchTile(
                icon: Icons.mark_email_read_outlined,
                iconBg: Colors.amber.shade50,
                iconColor: Colors.amber.shade600,
                title: 'Newsletter',
                subtitle: 'Weekly deals straight to email',
                value: settings.newsletter,
                textColor: textColor,
                subColor: subColor,
                onChanged: (v) =>
                    context.read<SettingsProvider>().setNewsletter(v),
              ),
              _divider(divColor),

              // Clear cache
              _navTile(
                icon: Icons.cleaning_services_outlined,
                iconBg: Colors.blueGrey.shade50,
                iconColor: Colors.blueGrey.shade400,
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                textColor: textColor,
                subColor: subColor,
                onTap: () => _showConfirmDialog(
                  context,
                  title: 'Clear Cache?',
                  message:
                      'This will clear all cached data. '
                      'Your orders and account data are safe.',
                  onConfirm: () => ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar('Cache cleared successfully', _green),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── ABOUT ─────────────────────────────────────────────────────────
          _sectionCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            cardColor: cardColor,
            divColor: divColor,
            textColor: textColor,
            children: [
              _navTile(
                icon: Icons.description_outlined,
                iconBg: Colors.grey.shade100,
                iconColor: Colors.grey.shade600,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms of service',
                textColor: textColor,
                subColor: subColor,
                onTap: () {},
              ),
              _divider(divColor),
              _navTile(
                icon: Icons.privacy_tip_outlined,
                iconBg: Colors.grey.shade100,
                iconColor: Colors.grey.shade600,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                textColor: textColor,
                subColor: subColor,
                onTap: () {},
              ),
              _divider(divColor),
              _navTile(
                icon: Icons.help_outline_rounded,
                iconBg: Colors.grey.shade100,
                iconColor: Colors.grey.shade600,
                title: 'Help & Support',
                subtitle: 'FAQs and contact us',
                textColor: textColor,
                subColor: subColor,
                onTap: () {},
              ),
              _divider(divColor),
              // App version
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: _green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vistora',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Version 1.0.0 | Devloped By Kartik Maheshwari',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── RESET ─────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _showConfirmDialog(
              context,
              title: 'Reset All Settings?',
              message: 'This will restore all settings to default.',
              onConfirm: () async {
                await context.read<SettingsProvider>().resetAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar('Settings reset to default', _green),
                  );
                }
              },
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restore_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reset All Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color cardColor,
    required Color divColor,
    required Color textColor,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: cardColor,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Icon(icon, color: _green, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        Divider(color: divColor, height: 1),
        ...children,
      ],
    ),
  );

  // ── Switch tile ────────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color subColor,
    bool enabled = true,
    void Function(bool)? onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: enabled ? iconBg : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: enabled ? iconColor : Colors.grey.shade300,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? textColor : Colors.grey.shade400,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 11, color: subColor),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _green,
          inactiveThumbColor: enabled ? null : Colors.grey.shade300,
        ),
      ],
    ),
  );

  // ── Nav tile (arrow) ───────────────────────────────────────────────────────
  Widget _navTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subColor),
        ],
      ),
    ),
  );

  // ── Dropdown tile ──────────────────────────────────────────────────────────
  Widget _dropdownTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> options,
    required int selected,
    required Color textColor,
    required Color subColor,
    required Color cardColor,
    required void Function(int) onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 11, color: subColor),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selected,
              isDense: true,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _greenDark,
              ),
              dropdownColor: cardColor,
              borderRadius: BorderRadius.circular(12),
              items: List.generate(
                options.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    options[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _greenDark,
                    ),
                  ),
                ),
              ),
              onChanged: (i) {
                if (i != null) onChanged(i);
              },
            ),
          ),
        ),
      ],
    ),
  );

  Widget _divider(Color color) =>
      Divider(color: color, height: 1, indent: 68, endIndent: 0);

  // ── Change password dialog ────────────────────────────────────────────────
  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true;
    bool obscure2 = true;
    bool obscure3 = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: _green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pwField(
                ctx,
                'Current Password',
                currentCtrl,
                obscure1,
                () => setDlgState(() => obscure1 = !obscure1),
              ),
              const SizedBox(height: 12),
              _pwField(
                ctx,
                'New Password',
                newCtrl,
                obscure2,
                () => setDlgState(() => obscure2 = !obscure2),
              ),
              const SizedBox(height: 12),
              _pwField(
                ctx,
                'Confirm Password',
                confirmCtrl,
                obscure3,
                () => setDlgState(() => obscure3 = !obscure3),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar(
                      'New passwords do not match',
                      Colors.red.shade500,
                    ),
                  );
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar(
                      'Password must be at least 6 characters',
                      Colors.red.shade500,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Password updated successfully', _green),
                );
              },
              child: Text(
                'Update',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(
    BuildContext ctx,
    String hint,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle,
  ) => TextField(
    controller: ctrl,
    obscureText: obscure,
    cursorColor: _green,
    style: GoogleFonts.poppins(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(Icons.lock_outline, color: _green, size: 18),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey.shade400,
          size: 18,
        ),
        onPressed: toggle,
      ),
      filled: true,
      fillColor: Theme.of(ctx).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _green, width: 1.5),
      ),
    ),
  );

  // ── Confirm dialog ─────────────────────────────────────────────────────────
  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              'Confirm',
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

  SnackBar _snackBar(String msg, Color color) => SnackBar(
    content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
