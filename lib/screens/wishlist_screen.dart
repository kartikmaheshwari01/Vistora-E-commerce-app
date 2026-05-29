import 'package:fire_flutter/model/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        iconTheme:
            theme.appBarTheme.iconTheme ??
            const IconThemeData(color: Colors.white),
        title: Text(
          "Wishlist",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
      ),

      body: Wishlist.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 90,
                    color: theme.hintColor.withOpacity(0.4),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Your wishlist is empty",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Items you like will appear here",
                    style: GoogleFonts.poppins(color: theme.hintColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: Wishlist.items.length,
              itemBuilder: (context, index) {
                final item = Wishlist.items[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(
                          theme.brightness == Brightness.dark ? 0.3 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(item.image),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              item.price,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? theme.colorScheme.secondary
                                    : theme.primaryColorDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            Wishlist.removeItem(item.name);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${item.name} removed",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        },

                        icon: Icon(
                          Icons.favorite,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
