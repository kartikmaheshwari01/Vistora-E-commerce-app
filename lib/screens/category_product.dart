import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/cart_model.dart';
import 'package:fire_flutter/model/product_model.dart';
import 'package:fire_flutter/model/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Per-category theme colours (kept local — pure UI config) ─────────────────
final Map<String, Map<String, dynamic>> categoryThemes = {
  "Clothes": {
    "gradient": [const Color(0xFF43A047), const Color(0xFF81C784)],
    "light": const Color(0xFFE8F5E9),
    "image": "assets/images/clothes.png",
  },
  "Electronics": {
    "gradient": [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    "light": const Color(0xFFE3F2FD),
    "image": "assets/images/eletronics.png",
  },
  "Health": {
    "gradient": [const Color(0xFFAD1457), const Color(0xFFF06292)],
    "light": const Color(0xFFFCE4EC),
    "image": "assets/images/health.png",
  },
  "Furniture": {
    "gradient": [const Color(0xFFF57F17), const Color(0xFFFFD54F)],
    "light": const Color(0xFFFFF8E1),
    "image": "assets/images/furniture.png",
  },
  "Kitchen": {
    "gradient": [const Color(0xFF6A1B9A), const Color(0xFFBA68C8)],
    "light": const Color(0xFFF3E5F5),
    "image": "assets/images/kitchen.png",
  },
};

// ─── Category Screen ──────────────────────────────────────────────────────────
class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final String categoryImage;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoryImage,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // ── Firestore stream — filtered by category ────────────────────────────────
  late final Stream<QuerySnapshot> _stream = FirebaseFirestore.instance
      .collection('products')
      .where('category', isEqualTo: widget.categoryName)
      .snapshots();

  // ── Sort & search state ────────────────────────────────────────────────────
  String _sortBy = "Popular";
  bool _searchActive = false;
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final List<String> _sortOptions = [
    "Popular",
    "Price: Low to High",
    "Price: High to Low",
    "Rating",
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Apply search then sort (client-side on the already-fetched list) ────────
  List<ProductModel> _applyFilters(List<ProductModel> raw) {
    // 1. search filter
    List<ProductModel> list = _searchQuery.trim().isEmpty
        ? raw
        : raw.where((p) => p.matchesQuery(_searchQuery)).toList();

    // 2. sort
    switch (_sortBy) {
      case "Price: Low to High":
        list.sort((a, b) => a.numericPrice.compareTo(b.numericPrice));
        break;
      case "Price: High to Low":
        list.sort((a, b) => b.numericPrice.compareTo(a.numericPrice));
        break;
      case "Rating":
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break; // "Popular" → Firestore order
    }
    return list;
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchQuery = '';
        _searchCtrl.clear();
      } else {
        Future.delayed(
          const Duration(milliseconds: 80),
          () => _searchFocus.requestFocus(),
        );
      }
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme =
        categoryThemes[widget.categoryName] ?? categoryThemes["Clothes"]!;
    final gradientColors = theme["gradient"] as List<Color>;
    final lightColor = theme["light"] as Color;
    final image = theme["image"] as String;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          // ── parse docs once ──────────────────────────────────────────────
          final allProducts = snapshot.hasData
              ? snapshot.data!.docs.map((d) => ProductModel.fromDoc(d)).toList()
              : <ProductModel>[];

          final products = _applyFilters(allProducts);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SLIVER APP BAR ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: _searchActive ? 160 : 200,
                pinned: true,
                elevation: 0,
                backgroundColor: gradientColors[0],
                automaticallyImplyLeading: false,
                leading: GestureDetector(
                  onTap: () {
                    if (_searchActive) {
                      _toggleSearch();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _searchActive
                          ? Icons.close_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _searchActive
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30,
                          right: -20,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: -30,
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 24,
                            top: 80,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Image.asset(
                                      image,
                                      color: Colors.white,
                                      width: 26,
                                      height: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.categoryName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // Live count updates with stream
                                      Text(
                                        snapshot.connectionState ==
                                                ConnectionState.waiting
                                            ? 'Loading...'
                                            : '${products.length} product${products.length == 1 ? '' : 's'} found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // ── Animated search bar ───────────────────
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _searchActive
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: _searchCtrl,
                                            focusNode: _searchFocus,
                                            onChanged: (val) => setState(
                                              () => _searchQuery = val,
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: const Color(0xFF1A1A2E),
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search in ${widget.categoryName}...',
                                              hintStyle: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey.shade400,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                                color: gradientColors[0],
                                                size: 20,
                                              ),
                                              suffixIcon:
                                                  _searchQuery.isNotEmpty
                                                  ? GestureDetector(
                                                      onTap: () => setState(() {
                                                        _searchQuery = '';
                                                        _searchCtrl.clear();
                                                      }),
                                                      child: Icon(
                                                        Icons.clear_rounded,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                        size: 18,
                                                      ),
                                                    )
                                                  : null,
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── SORT BAR ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: gradientColors[0],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Sort by:",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF444444),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _sortOptions.map((option) {
                              final selected = _sortBy == option;
                              return GestureDetector(
                                onTap: () => setState(() => _sortBy = option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? gradientColors[0]
                                        : lightColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    option,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : gradientColors[0],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(height: 8, color: const Color(0xFFF7F8FA)),
              ),

              // ── LOADING ────────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: gradientColors[0],
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              // ── ERROR ──────────────────────────────────────────────────
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: _errorState(snapshot.error.toString()),
                )
              // ── EMPTY (no results after search/filter) ─────────────────
              else if (products.isEmpty)
                SliverFillRemaining(
                  child: _emptyState(
                    _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : 'No products in ${widget.categoryName} yet.',
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined,
                    gradientColors[0],
                  ),
                )
              // ── PRODUCTS GRID ──────────────────────────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProductCard(
                        product: products[index],
                        accentColor: gradientColors[0],
                        lightColor: lightColor,
                      ),
                      childCount: products.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── State helpers ──────────────────────────────────────────────────────────
  Widget _emptyState(String msg, IconData icon, Color color) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
        ),
      ],
    ),
  );

  Widget _errorState(String err) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            err,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final Color accentColor;
  final Color lightColor;

  const _ProductCard({
    required this.product,
    required this.accentColor,
    required this.lightColor,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool get _wishlisted => Wishlist.isInWishlist(widget.product.name);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductDetailSheet(
          product: widget.product,
          accentColor: widget.accentColor,
          lightColor: widget.lightColor,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ───────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: widget.lightColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _productImage(widget.product.img),
                      ),
                    ),
                  ),

                  // Discount badge
                  if (widget.product.discount.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${widget.product.discount} OFF",
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_wishlisted) {
                            Wishlist.removeItem(widget.product.name);
                          } else {
                            Wishlist.addItem(
                              WishlistItem(
                                name: widget.product.name,
                                price: widget.product.price,
                                image: widget.product.img,
                              ),
                            );
                          }
                        });
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          _wishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: _wishlisted
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.product.rating.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.displayPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.accentColor,
                            ),
                          ),
                          if (widget.product.displayOriginalPrice.isNotEmpty)
                            Text(
                              widget.product.displayOriginalPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
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
    );
  }
}

// ─── Product Detail Bottom Sheet ──────────────────────────────────────────────
class _ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final Color accentColor;
  final Color lightColor;

  const _ProductDetailSheet({
    required this.product,
    required this.accentColor,
    required this.lightColor,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  bool _wishlisted = false;

  @override
  void initState() {
    super.initState();
    _wishlisted = Wishlist.isInWishlist(widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Product image
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: widget.lightColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: _productImage(product.img, height: 70)),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${product.rating} rating",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.displayPrice,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                          ),
                        ),
                        if (product.displayOriginalPrice.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            product.displayOriginalPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        if (product.discount.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${product.discount} OFF",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "Description",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              // ── Wishlist button ──────────────────────────────────────
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_wishlisted) {
                        Wishlist.removeItem(product.name);
                        _wishlisted = false;
                      } else {
                        Wishlist.addItem(
                          WishlistItem(
                            name: product.name,
                            price: product.price,
                            image: product.img,
                          ),
                        );
                        _wishlisted = true;
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _wishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _wishlisted ? Colors.redAccent : widget.accentColor,
                    size: 18,
                  ),
                  label: Text(
                    _wishlisted ? "Wishlisted" : "Wishlist",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Add to Cart button ────────────────────────────────────
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ Fixed: uses actual product data, not hardcoded "Shoes"
                    Cart.addItem(
                      CartItem(
                        name: product.name,
                        price: product.numericPrice,
                        image: product.img,
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: widget.accentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${product.name} added to cart",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Add to Cart",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Shared image builder (asset + network) ───────────────────────────────────
Widget _productImage(String path, {double? height}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.contain,
      height: height,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: Colors.grey.shade300,
      ),
    );
  }
  return Image.asset(
    path,
    fit: BoxFit.contain,
    height: height,
    errorBuilder: (_, __, ___) => Icon(
      Icons.image_not_supported_outlined,
      size: 36,
      color: Colors.grey.shade300,
    ),
  );
}
