import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ARBubbleOverlay extends StatefulWidget {
  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final Map<String, String> translations;
  final String targetLang;
  final Size widgetSize;

  const ARBubbleOverlay({
    super.key,
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.translations,
    required this.targetLang,
    required this.widgetSize,
  });

  @override
  State<ARBubbleOverlay> createState() => _ARBubbleOverlayState();
}

class _ARBubbleOverlayState extends State<ARBubbleOverlay> {
  // Store which bubbles are expanded (default to false, start collapsed)
  final Set<String> _expandedBlocks = {};

  @override
  Widget build(BuildContext context) {
    List<Widget> highlightWidgets = [];
    List<Widget> expandedWidgets = [];

    for (int i = 0; i < widget.recognizedText.blocks.length; i++) {
      final block = widget.recognizedText.blocks[i];
      final originalText = block.text.trim();
      final translated = widget.translations[originalText] ?? "Translating...";
      
      if (translated.isEmpty) continue;

      final rect = _scaleRect(
        rect: block.boundingBox,
        imageSize: widget.imageSize,
        widgetSize: widget.widgetSize,
        rotation: widget.rotation,
      );

      final isArabic = widget.targetLang == 'Arabic';
      final isExpanded = _expandedBlocks.contains(originalText);

      final widgetToAdd = Positioned(
          left: rect.left,
          top: rect.top,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBlocks.remove(originalText);
                } else {
                  _expandedBlocks.add(originalText);
                }
              });
            },
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: rect.width > 60 ? rect.width + 60 : 180,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      translated,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Container(
                    width: rect.width,
                    height: rect.height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
          ),
      );

      if (isExpanded) {
        expandedWidgets.add(widgetToAdd);
      } else {
        highlightWidgets.add(widgetToAdd);
      }
    }

    return Stack(
      children: [
        ...highlightWidgets,
        ...expandedWidgets,
      ],
    );
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

    final double widgetAspectRatio = widgetSize.width / widgetSize.height;
    final double imageAspectRatio = imageWidth / imageHeight;
    
    double renderWidth, renderHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (widgetAspectRatio > imageAspectRatio) {
      renderHeight = widgetSize.height;
      renderWidth = imageWidth * (widgetSize.height / imageHeight);
      offsetX = (widgetSize.width - renderWidth) / 2;
    } else {
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
}
