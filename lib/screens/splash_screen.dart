import 'dart:async';
import 'package:fire_flutter/signup/signup_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;

  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> glowAnimation;

  @override
  void initState() {
    super.initState();

    /// MAIN ANIMATION
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    /// ROTATING LOADER
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeIn));

    scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
        );

    glowAnimation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    /// Navigate after animation completes
    Timer(const Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Sign_Up()),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE8F5E9),
              Color(0xFFA5D6A7),
              Color(0xFF2E7D32),
            ],
          ),
        ),

        child: Center(
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// GLOWING CIRCLE
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade800.withOpacity(
                                  glowAnimation.value * 0.5,
                                ),
                                blurRadius: 35,
                                spreadRadius: 10,
                              ),
                            ],
                          ),

                          child: Center(
                            child: Text(
                              "V",
                              style: TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// APP NAME
                        Text(
                          "Vistora",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Colors.green.shade800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// TAGLINE
                        Text(
                          "Minimal • Elegant • Smart Shopping",
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: Colors.green.shade700,
                          ),
                        ),

                        const SizedBox(height: 45),

                        /// CUSTOM ROTATING LOADER
                        RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green.shade800,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
