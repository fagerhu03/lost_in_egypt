import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AROverlayPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final Map<String, String> translations; // Original text to translated text map
  final String targetLang;

  AROverlayPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.translations,
    required this.targetLang,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final TextBlock block in recognizedText.blocks) {
      final rect = _scaleRect(
        rect: block.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
        rotation: rotation,
      );

      final String originalText = block.text.trim();
      final String translated = translations[originalText] ?? "Translating...";

      if (translated.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: translated,
            style: const TextStyle(
              color: Color(0xFF4A3D2E), // Theme dark brown
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: targetLang == 'Arabic' ? TextDirection.rtl : TextDirection.ltr,
          textAlign: targetLang == 'Arabic' ? TextAlign.right : TextAlign.left,
        );
        
        // Define max width to prevent bubbles from going infinitely wide
        textPainter.layout(maxWidth: rect.width > 60 ? rect.width + 40 : 150);

        // Center the bubble horizontally and vertically on the original text block
        double textX = rect.left + (rect.width / 2) - (textPainter.width / 2);
        double textY = rect.top + (rect.height / 2) - (textPainter.height / 2);

        // Padding for the bubble
        const double padX = 8.0;
        const double padY = 6.0;

        // Keep bounds on screen
        if (textX < padX) textX = padX;
        if (textY < padY) textY = padY;
        if (textX + textPainter.width + padX > size.width) {
          textX = size.width - textPainter.width - padX;
        }

        // Drop shadow paint
        final Paint shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        // Bubble background paint
        final Paint backgroundPaint = Paint()
          ..color = const Color(0xFFFFFDF4).withOpacity(0.95)
          ..style = PaintingStyle.fill;

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            textX - padX, 
            textY - padY, 
            textPainter.width + (padX * 2), 
            textPainter.height + (padY * 2)
          ),
          const Radius.circular(8),
        );

        // Draw shadow then bubble
        canvas.drawRRect(bubbleRect.shift(const Offset(0, 3)), shadowPaint);
        canvas.drawRRect(bubbleRect, backgroundPaint);

        // Draw text
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
    double imageWidth = imageSize.width;
    double imageHeight = imageSize.height;

    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      imageWidth = imageSize.height;
      imageHeight = imageSize.width;
    }

    // BoxFit.contain logic
    final double widgetAspectRatio = widgetSize.width / widgetSize.height;
    final double imageAspectRatio = imageWidth / imageHeight;
    
    double renderWidth, renderHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (widgetAspectRatio > imageAspectRatio) {
      // Letterbox on left/right
      renderHeight = widgetSize.height;
      renderWidth = imageWidth * (widgetSize.height / imageHeight);
      offsetX = (widgetSize.width - renderWidth) / 2;
    } else {
      // Letterbox on top/bottom
      renderWidth = widgetSize.width;
      renderHeight = imageHeight * (widgetSize.width / imageWidth);
      offsetY = (widgetSize.height - renderHeight) / 2;
    }

    scaleX = renderWidth / imageWidth;
    scaleY = renderHeight / imageHeight;

    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return Rect.fromLTRB(
        rect.top * scaleX + offsetX,
        rect.left * scaleY + offsetY,
        rect.bottom * scaleX + offsetX,
        rect.right * scaleY + offsetY,
      );
    } else {
      return Rect.fromLTRB(
        rect.left * scaleX + offsetX,
        rect.top * scaleY + offsetY,
        rect.right * scaleX + offsetX,
        rect.bottom * scaleY + offsetY,
      );
    }
  }

  @override
  bool shouldRepaint(AROverlayPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText ||
        oldDelegate.translations != translations ||
        oldDelegate.targetLang != targetLang;
  }
}
