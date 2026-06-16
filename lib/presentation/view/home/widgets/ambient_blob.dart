import 'dart:ui';
import 'package:flutter/material.dart';

class AmbientBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blurSigma;

  const AmbientBlob({
    super.key,
    required this.color,
    required this.size,
    this.blurSigma = 90.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
