import 'package:fire_flutter/model/usermodel.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class MainScreen extends StatefulWidget {
  final UserModal user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(user: widget.user),
      CartScreen(),
      ProfileScreen(user: widget.user),
      const WishlistScreen(),
    ];

    return Scaffold(
      body: screens[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade500,
        unselectedItemColor: Colors.grey,

        onTap: (i) {
          setState(() {
            index = i;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: "Wishlist",
          ),
        ],
      ),
    );
  }
}