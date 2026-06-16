import 'package:flutter/material.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';
import 'package:hazmove_robot/core/style/glass_container.dart';


class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            borderRadius: BorderRadius.circular(30),
            blur: 25.0, // Increased blur for the App Bar specifically
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HAZMOVE ROBOT',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
