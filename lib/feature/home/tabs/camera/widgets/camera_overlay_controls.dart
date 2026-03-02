import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
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
    required String value,
    required Function(String) onChanged,
  }) {
    final languages = CameraCubit.availableLanguages.keys.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
                      MapFocusService.instance.switchToTab(0);
                    }
                  },
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
                      value: state.sourceLang,
                      onChanged: (newLang) => cubit.setSourceLanguage(newLang),
                    ),
                  const SizedBox(height: 8),
                  if (state.isTranslateMode)
                    _buildLanguageDropdown(
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
                          color: Colors.white.withOpacity(0.92),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.hardEdge,
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
                                    color: Color(0xFFFFFDF4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    size: 36,
                                    color: Color(0xFF4A3D2E),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 84),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                  // AR Translate Button
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.21,
                    top: -20, // Slightly above the capture/gallery buttons
                    child: Material(
                      color: state.isTranslateMode
                          ? const Color(0xFF4A3D2E)
                          : Colors.white.withOpacity(0.92),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.2),
                      child: InkWell(
                        onTap: () => cubit.toggleTranslateMode(),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.translate,
                            size: 20,
                            color: state.isTranslateMode
                                ? Colors.white
                                : const Color(0xFF4A3D2E),
                          ),
                        ),
                      ),
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
