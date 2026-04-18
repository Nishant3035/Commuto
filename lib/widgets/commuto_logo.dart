import 'package:flutter/material.dart';

class CommutoLogo extends StatelessWidget {
  const CommutoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image from asset
        Image.asset(
          'assets/images/commuto_logo.png',
          height: 220,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
