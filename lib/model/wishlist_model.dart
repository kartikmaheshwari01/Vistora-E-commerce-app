import 'package:cloud_firestore/cloud_firestore.dart';

// ─── WishlistItem ─────────────────────────────────────────────────────────────
class WishlistItem {
  final String name;
  final String price;   // display string e.g. "Rs. 2,999"
  final String image;

  const WishlistItem({
    required this.name,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'image': image,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        name: json['name'] ?? '',
        price: json['price'] ?? '',
        image: json['image'] ?? '',
      );
}

// ─── Wishlist (Firestore-backed static store) ─────────────────────────────────
//
// Firestore path:  users/{uid}/wishlist/{name}
//   document id  = product name (sanitised)
//   fields       = name, price, image
//
// Call Wishlist.init(uid) once after login / app start.
// All mutations auto-sync to Firestore.
// ─────────────────────────────────────────────────────────────────────────────
class Wishlist {
  Wishlist._();

  static final List<WishlistItem> items = [];
  static String? _uid;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection reference for the current user ────────────────────────────
  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('wishlist');

  /// Call once right after the user logs in.
  /// Loads persisted wishlist from Firestore into [items].
  static Future<void> init(String uid) async {
    _uid = uid;
    items.clear();

    final snap = await _col.get();
    for (final doc in snap.docs) {
      items.add(WishlistItem.fromJson(doc.data() as Map<String, dynamic>));
    }
  }

  /// Clears the in-memory list (call on logout — does NOT delete Firestore data).
  static void clear() {
    items.clear();
    _uid = null;
  }

  /// Add item; replaces if the same product name already exists.
  static Future<void> addItem(WishlistItem item) async {
    items.removeWhere((i) => i.name == item.name);
    items.add(item);

    if (_uid != null) {
      await _col.doc(_docId(item.name)).set(item.toJson());
    }
  }

  /// Remove item by product name.
  static Future<void> removeItem(String name) async {
    items.removeWhere((i) => i.name == name);

    if (_uid != null) {
      await _col.doc(_docId(name)).delete();
    }
  }

  /// Whether the product is already in the wishlist.
  static bool isInWishlist(String name) =>
      items.any((i) => i.name == name);

  // Firestore document id — strip characters that Firestore doesn't allow
  static String _docId(String name) =>
      name.replaceAll(RegExp(r'[\/\.]'), '_');
}