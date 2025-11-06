import 'package:flutter/material.dart';

/// Helper widget to create text with a black outline and white fill
class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const OutlinedText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Stroke layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize > 100 ? 15 : 7
              ..color = Colors.black,
          ),
          textHeightBehavior: TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
        // Fill layer
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.white,
          ),
          textHeightBehavior: TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
      ],
    );
  }
}

/// Helper widget to build list item title with optional outline styling
class ListItemTitle extends StatelessWidget {
  final int index;
  final String label;
  final bool isSelected;
  final double fontSize;

  const ListItemTitle({
    super.key,
    required this.index,
    required this.label,
    required this.isSelected,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Stack(
        children: [
          // Stroke layer
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${index + 1}. ',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Fill layer
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${index + 1}. ',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${index + 1}. ',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Helper widget to build an arrow indicator with outline
class ArrowIndicator extends StatelessWidget {
  const ArrowIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          '→',
          style: TextStyle(
            fontSize: 20,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        const Text(
          '→',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
