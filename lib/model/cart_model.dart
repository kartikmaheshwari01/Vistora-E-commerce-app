import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── CartItem ─────────────────────────────────────────────────────────────────
class CartItem {
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'image': image,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    image: json['image'] ?? '',
    quantity: json['quantity'] ?? 1,
  );
}

// ─── Cart Store ───────────────────────────────────────────────────────────────
class Cart {
  Cart._();

  static String? _uid;

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final ValueNotifier<List<CartItem>> notifier =
      ValueNotifier<List<CartItem>>([]);

  // Getter for easy access
  static List<CartItem> get items => notifier.value;

  // Firestore collection
  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('cart');

  // ────────────────────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> init(String uid) async {
    _uid = uid;

    final snap = await _col.get();

    notifier.value = snap.docs
        .map((doc) => CartItem.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CLEAR
  // ────────────────────────────────────────────────────────────────────────────
  static void clear() {
    notifier.value = [];
    _uid = null;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ADD ITEM
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> addItem(CartItem item) async {
    final list = List<CartItem>.from(notifier.value);

    final index = list.indexWhere((i) => i.name == item.name);

    if (index != -1) {
      // Increase quantity if item exists
      list[index].quantity++;
    } else {
      list.add(item);
    }

    notifier.value = list;

    if (_uid != null) {
      final existingItem = list.firstWhere((i) => i.name == item.name);

      await _col.doc(_docId(item.name)).set(existingItem.toJson());
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // REMOVE ITEM
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> removeItem(String name) async {
    final list = List<CartItem>.from(notifier.value);

    final index = list.indexWhere((i) => i.name == name);

    if (index == -1) return;

    if (list[index].quantity > 1) {
      list[index].quantity--;
    } else {
      list.removeAt(index);
    }

    notifier.value = list;

    if (_uid != null) {
      final itemExists = list.any((i) => i.name == name);

      if (itemExists) {
        final item = list.firstWhere((i) => i.name == name);

        await _col.doc(_docId(name)).set(item.toJson());
      } else {
        await _col.doc(_docId(name)).delete();
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────────────────
  static bool isInCart(String name) =>
      notifier.value.any((i) => i.name == name);

  static double get subtotal {
    // Explicitly uses 0.0 and double typing to avoid precision or type issues
    return notifier.value.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // If subtotal is greater than 2000, DC is free (0). Otherwise, it is 150.
  static double get deliveryFee {
    if (notifier.value.isEmpty) return 0.0;
    return subtotal > 2000.0 ? 0.0 : 150.0;
  }

  static double get total {
    return subtotal + deliveryFee;
  }

  // Firestore-safe doc id
  static String _docId(String name) {
    return name.replaceAll(RegExp(r'[\/\.]'), '_');
  }
}
