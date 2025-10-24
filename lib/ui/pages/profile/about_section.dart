import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  final String title;
  final Color textColor;
  const AboutSection({super.key, required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Match the semi-opaque white, rounded and bordered look used for
      // the channels container and the contacts search box.
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor.withOpacity(0.8), height: 1.45),
      ),
    );
  }
}
