import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/audio_service.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double imageSize;

  const CategoryCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
    this.imageSize = 120, // Default size
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Use the generated image icon as the background/central element
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Hero(
                    tag: 'hero_$title',
                    child: Image.asset(
                      imagePath,
                      height: imageSize, // Use dynamic size
                    ),
                  ),
                ),
              ),
              // Title at the top center
              Positioned(
                top: 15,
                left: 0,
                right: 0,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lalezar(
                    fontSize: 24,
                    color: const Color(0xFF1A1A2E), // Dark Navy/Blue-ish
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
