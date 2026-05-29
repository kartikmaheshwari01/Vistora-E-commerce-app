// ── Add all admin emails here ─────────────────────────────────────────────────
// When a user logs in with any of these emails they get the admin panel button.
class AdminConfig {
  AdminConfig._();

  static const List<String> adminEmails = [
    'kumarkartik955@gmail.com',
    'ali.sheraz33227111@gmail.com',
  ];

  static bool isAdmin(String? email) {
    if (email == null || email.isEmpty) return false;
    return adminEmails.contains(email.toLowerCase().trim());
  }
}
