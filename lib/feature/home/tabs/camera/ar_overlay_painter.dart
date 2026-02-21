import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AROverlayPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final Map<String, String> translations; // Original text to translated text map

  AROverlayPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.translations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.greenAccent;

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final TextBlock block in recognizedText.blocks) {
      final rect = _scaleRect(
        rect: block.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
        rotation: rotation,
      );

      canvas.drawRect(rect, paint);

      final String originalText = block.text.trim();
      final String translated = translations[originalText] ?? "Translating...";

      if (translated.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: translated,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Ensure text is within bounds, adjust position if needed
        double textX = rect.left + 4;
        double textY = rect.top - 18;

        // If the text would go off screen to the left
        if (textX < 0) textX = 0;
        // If the text would go off screen to the top
        if (textY < 0) textY = 0;

        // Draw background for translated text
        canvas.drawRect(
          Rect.fromLTWH(textX - 2, textY - 2, textPainter.width + 4, textPainter.height + 4),
          backgroundPaint,
        );

        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    required InputImageRotation rotation,
  }) {
    double scaleX, scaleY;
    
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      scaleX = widgetSize.width / imageSize.height;
      scaleY = widgetSize.height / imageSize.width;
      
      return Rect.fromLTRB(
        rect.top * scaleX,
        rect.left * scaleY,
        rect.bottom * scaleX,
        rect.right * scaleY,
      );
    } else {
      scaleX = widgetSize.width / imageSize.width;
      scaleY = widgetSize.height / imageSize.height;
      
      return Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
    }
  }

  @override
  bool shouldRepaint(AROverlayPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText ||
        oldDelegate.translations != translations;
  }
}
