import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String price;          // e.g. "899" or "Rs.899"
  final String originalPrice;  // e.g. "1499" — for strikethrough
  final String discount;       // e.g. "40" or "40%" — for badge
  final String img;
  final String description;
  final String category;
  final double rating;
  final bool   isSpecialOffer;
  final String discountText;   // e.g. "40% off" — for offer banner

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.img,
    required this.description,
    required this.category,
    this.originalPrice  = '',
    this.discount       = '',
    this.rating         = 0.0,
    this.isSpecialOffer = false,
    this.discountText   = '',
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────
  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely handles bool true, string "true", or missing field
    final rawOffer = data['isSpecialOffer'];
    final isOffer  = rawOffer == true || rawOffer == 'true';

    return ProductModel(
      id:            doc.id,
      name:          data['name']          ?? '',
      price:         data['price']         ?? '0',
      originalPrice: data['originalPrice'] ?? '',
      discount:      data['discount']      ?? '',
      img:           data['img']           ?? '',
      description:   data['description']   ?? 'No description available.',
      category:      data['category']      ?? '',
      rating:        (data['rating'] as num?)?.toDouble() ?? 0.0,
      isSpecialOffer: isOffer,
      discountText:  data['discountText']  ?? '',
    );
  }

  // ── Model → Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'name':          name,
        'price':         price,
        'originalPrice': originalPrice,
        'discount':      discount,
        'img':           img,
        'description':   description,
        'category':      category,
        'rating':        rating,
        'isSpecialOffer': isSpecialOffer,
        'discountText':  discountText,
      };

  // ── Display price — always shows "Rs." prefix ─────────────────────────────
  String get displayPrice {
    final cleaned = price
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();
    return 'Rs.$cleaned';
  }

  // ── Display original price with prefix ────────────────────────────────────
  String get displayOriginalPrice {
    if (originalPrice.isEmpty) return '';
    final cleaned = originalPrice
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();
    return 'Rs.$cleaned';
  }

  // ── Display discount badge text e.g. "40% OFF" ────────────────────────────
  String get displayDiscount {
    if (discount.isEmpty) return '';
    final cleaned = discount.trim();
    // If already has %, just uppercase; else add %
    return cleaned.contains('%')
        ? '${cleaned.toUpperCase()} OFF'
        : '$cleaned% OFF';
  }

  // ── Convenience booleans used in home_screen ──────────────────────────────
  bool get hasOriginalPrice => originalPrice.isNotEmpty;
  bool get hasDiscount      => discount.isNotEmpty;
  bool get hasRating        => rating > 0;

  // ── Numeric price for cart & sort ─────────────────────────────────────────
  double get numericPrice =>
      double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  // ── Client-side search match ───────────────────────────────────────────────
  bool matchesQuery(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        price.toLowerCase().contains(q);
  }
}