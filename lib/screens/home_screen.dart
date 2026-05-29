import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_flutter/model/cart_model.dart';
import 'package:fire_flutter/model/product_model.dart';
import 'package:fire_flutter/model/usermodel.dart';
import 'package:fire_flutter/model/wishlist_model.dart';
import 'package:fire_flutter/screens/admin_config.dart';
import 'package:fire_flutter/screens/admin_fab.dart';
import 'package:fire_flutter/screens/category_product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final UserModal user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;

  // ── Search & Filter ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";

  // ── Streams declared once ──────────────────────────────────────────────────
  late final Stream<QuerySnapshot> _productsStream = _firestore
      .collection('products')
      .snapshots();

  late final Stream<QuerySnapshot> _specialOffersStream = _firestore
      .collection('products')
      .where('isSpecialOffer', isEqualTo: true)
      .snapshots();

  // ── Theme ──────────────────────────────────────────────────────────────────
  static final Color primaryGreen = const Color.fromARGB(255, 76, 175, 80);
  static final Color darkGreen = Colors.green.shade700;
  static const Color darkTextColor = Color(0xFF1E1E24);
  static const Color lightBgColor = Color(0xFFF9FAFC);

  final List<Map<String, String>> _categories = [
    {"name": "All", "img": "", "color": "0xFFE8F5E9"},
    {
      "name": "Clothes",
      "img": "assets/images/clothes.png",
      "color": "0xFFE8F5E9",
    },
    {
      "name": "Electronics",
      "img": "assets/images/eletronics.png",
      "color": "0xFFE0F2F1",
    },
    {
      "name": "Health",
      "img": "assets/images/health.png",
      "color": "0xFFFCE4EC",
    },
    {
      "name": "Furniture",
      "img": "assets/images/furniture.png",
      "color": "0xFFEFEBE9",
    },
    {
      "name": "Kitchen",
      "img": "assets/images/kitchen.png",
      "color": "0xFFF3E5F5",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(BuildContext ctx, ProductModel product) {
    Cart.addItem(
      CartItem(
        name: product.name,
        price: product.numericPrice,
        image: product.img,
      ),
    );
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          "${product.name} added to cart",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showProductDialog(BuildContext ctx, ProductModel product) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFFE8F5E9).withOpacity(0.4),
                  child: _productImage(product.img),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E1E24),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.displayPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  if (product.hasOriginalPrice) ...[
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
                  if (product.hasDiscount) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.displayDiscount,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (product.rating > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                product.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _addToCart(ctx, product);
            },
            child: Text(
              "Add to Cart",
              style: GoogleFonts.poppins(
                color: Theme.of(context).cardColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(String path, {double? height}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        height: height,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(
                child: CircularProgressIndicator(
                  color: primaryGreen,
                  strokeWidth: 2,
                ),
              ),
        errorBuilder: (_, __, ___) => Icon(
          Icons.image_not_supported_outlined,
          size: 40,
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
        size: 40,
        color: Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              "Exit App",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E1E24),
              ),
            ),
            content: Text(
              "Are you sure you want to close the application?",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Exit",
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).cardColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        floatingActionButton: const AdminFab(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _sectionTitle("Categories"),
              const SizedBox(height: 16),
              _buildCategories(context),
              const SizedBox(height: 28),
              _sectionTitle("Special Offers"),
              const SizedBox(height: 14),
              _buildSpecialOffers(context),
              const SizedBox(height: 28),
              _sectionTitle("Products"),
              const SizedBox(height: 14),
              _buildProductsGrid(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (Cleaned & Integrated with App Icon) ───────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: App Icon Asset + App Name + Minimal Initial Profile Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/images/vistora_icon.png",
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 18,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Vistora",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).cardColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.user.username.isNotEmpty
                      ? widget.user.username[0].toUpperCase()
                      : "U",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Hi, ${widget.user.username} 👋",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).cardColor.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "What are you looking for?",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 18),
          // Clean Minimal Search Bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1E1E24),
                    ),
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1E1E24),
        ),
      ),
    );
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catName = cat["name"]!;
          final isSelected = catName == "All" && _selectedCategory == "All";
          final bgColor = Color(int.parse(cat["color"]!));

          return GestureDetector(
            onTap: () {
              if (catName == "All") {
                setState(() => _selectedCategory = "All");
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      categoryName: catName,
                      categoryImage: cat["img"]!,
                    ),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryGreen : bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? darkGreen : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: cat["img"]!.isEmpty
                          ? Icon(
                              Icons.grid_view_rounded,
                              color: isSelected
                                  ? Theme.of(context).cardColor
                                  : primaryGreen,
                            )
                          : Image.asset(
                              cat["img"]!,
                              fit: BoxFit.contain,
                              color: isSelected
                                  ? Theme.of(context).cardColor
                                  : null,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.category_outlined,
                                color: isSelected
                                    ? Theme.of(context).cardColor
                                    : primaryGreen,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? primaryGreen
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1E1E24)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Special Offers ─────────────────────────────────────────────────────────
  Widget _buildSpecialOffers(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _specialOffersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _loadingPlaceholder(height: 120, horizontal: true);
        if (snapshot.hasError) return _errorBanner("Couldn't load offers.");

        var docs = snapshot.data?.docs ?? [];

        if (_searchQuery.isNotEmpty) {
          docs = docs
              .where(
                (d) => (d.data() as Map<String, dynamic>)['name']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()),
              )
              .toList();
        }

        if (docs.isEmpty)
          return _emptyState(
            "No special offers match search.",
            Icons.local_offer_outlined,
          );

        final offers = docs.map((d) => ProductModel.fromDoc(d)).toList();

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final offer = offers[i];
              return GestureDetector(
                onTap: () => _showProductDialog(context, offer),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen, darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _productImage(offer.img, height: 54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "LIMITED OFFER",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).cardColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              offer.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).cardColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer.discountText.isNotEmpty
                                  ? "${offer.displayPrice}  •  ${offer.discountText}"
                                  : offer.displayPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).cardColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Products Grid (Minimal Premium Feel) ──────────────────────────────────
  Widget _buildProductsGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _loadingPlaceholder(height: 400, horizontal: false);
        if (snapshot.hasError) return _errorBanner("Couldn't load products.");

        final docs = snapshot.data?.docs ?? [];

        List<ProductModel> products = docs
            .map((d) => ProductModel.fromDoc(d))
            .where((p) => p.isSpecialOffer != true)
            .toList();

        if (_selectedCategory != "All") {
          products = products
              .where((p) => p.category == _selectedCategory)
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          products = products
              .where((p) => p.matchesQuery(_searchQuery))
              .toList();
        }

        if (products.isEmpty)
          return _emptyState(
            "No items match your criteria.",
            Icons.inventory_2_outlined,
          );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.74,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () => _showProductDialog(context, product),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // Applied your subtle pastel green to give the image card a rich minimalist lift
                          color: const Color(0xFFE8F5E9).withOpacity(0.35),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _productImage(product.img),
                              ),
                            ),
                            if (product.hasDiscount)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.displayDiscount,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).cardColor,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: StatefulBuilder(
                                builder: (ctx, setFavState) {
                                  bool isFav = Wishlist.isInWishlist(
                                    product.name,
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      if (isFav) {
                                        Wishlist.removeItem(product.name);
                                      } else {
                                        Wishlist.addItem(
                                          WishlistItem(
                                            name: product.name,
                                            price: product.displayPrice,
                                            image: product.img,
                                          ),
                                        );
                                      }
                                      setFavState(() {});
                                    },
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 18,
                                        color: isFav
                                            ? Colors.red.shade600
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1E1E24),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                product.displayPrice,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              if (product.hasOriginalPrice) ...[
                                const SizedBox(width: 6),
                                Text(
                                  product.displayOriginalPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
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
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _loadingPlaceholder({
    required double height,
    required bool horizontal,
  }) {
    if (horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.74,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
