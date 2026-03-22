import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryHeader extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final String? heroTag;

  const CategoryHeader({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Image.asset(imagePath, height: 100),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              ),
              child: Text(
                title,
                style: GoogleFonts.lalezar(
                  fontSize: 32,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StyledNextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;

  const StyledNextButton({super.key, required this.text, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF4FC3F7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.lalezar(
            fontSize: 36,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

class StyledBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        ),
        child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool hasRemove;
  final TextEditingController? controller;
  final VoidCallback? onDelete;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.hint,
    this.hasRemove = false,
    this.controller,
    this.onDelete,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
      ),
      child: Row(
        children: [
          if (hasRemove)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lalezar(color: Colors.black54, fontSize: 18),
                border: InputBorder.none,
              ),
              style: GoogleFonts.lalezar(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Decoration (The dark oval with lines)
            Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF81D4FA), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(fontSize: 20, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const DialogButton({super.key, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        ),
        child: Text(
          text,
          style: GoogleFonts.lalezar(fontSize: 20, color: const Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}
