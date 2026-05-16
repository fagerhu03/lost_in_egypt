import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../presentation/bloc/camera_cubit.dart';
import '../presentation/bloc/camera_state.dart';

class CameraOverlayControls extends StatelessWidget {
  final CameraReady state;
  final CameraCubit cubit;
  final bool showGalleryImage;

  const CameraOverlayControls({
    super.key,
    required this.state,
    required this.cubit,
    required this.showGalleryImage,
  });

  Widget _buildLanguageDropdown({
    required BuildContext context,
    required String value,
    required Function(String) onChanged,
  }) {
    final languages = CameraCubit.availableLanguages.keys.toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white70,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white30 : Colors.black26),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? Colors.black87 : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12),
          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black87),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: languages.map<DropdownMenuItem<String>>((String lang) {
            return DropdownMenuItem<String>(value: lang, child: Text(lang));
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (showGalleryImage) {
                      cubit.clearGalleryImage();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                if (!showGalleryImage)
                  IconButton(
                    icon: Icon(
                      state.flashMode == FlashMode.off ? Icons.flash_off :
                      state.flashMode == FlashMode.auto ? Icons.flash_auto :
                      state.flashMode == FlashMode.always ? Icons.flash_on :
                      Icons.highlight, // Torch
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => cubit.toggleFlash(),
                  ),
                Text(
                  showGalleryImage ? "Translation" : "Lens",
                  style: const TextStyle(
                    fontFamily: "Marcellus",
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: showGalleryImage ? null : () => cubit.flipCamera(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (state.isTranslateMode)
                    _buildLanguageDropdown(
                      context: context,
                      value: state.sourceLang,
                      onChanged: (newLang) => cubit.setSourceLanguage(newLang),
                    ),
                  const SizedBox(height: 8),
                  if (state.isTranslateMode)
                    _buildLanguageDropdown(
                      context: context,
                      value: state.targetLang,
                      onChanged: (newLang) => cubit.setTargetLanguage(newLang),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 30,
              right: 30,
            ),
            child: SizedBox(
              height: 84, // ensures the stack has the height of the largest element
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Material(
                          color: Theme.of(context).colorScheme.surface,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.hardEdge,
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                          child: InkWell(
                            onTap: () => cubit.pickFromGallery(),
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.photo_library_outlined,
                                color: Color(0xFF4A3D2E),
                              ),
                            ),
                          ),
                        ),
                        // Hide capture button when showing gallery image
                        if (!showGalleryImage)
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () => cubit.captureAndAnalyze(),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 4),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 32,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 84),
                        // AR Translate Button
                        Material(
                          color: state.isTranslateMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.hardEdge,
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                          child: InkWell(
                            onTap: () => cubit.toggleTranslateMode(),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.translate,
                                size: 22,
                                color: state.isTranslateMode
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
