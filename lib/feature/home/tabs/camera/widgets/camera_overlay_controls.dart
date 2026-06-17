import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white70,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? Colors.white30 : Colors.black26),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? Colors.black87 : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12.sp),
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
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28.r,
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
                      size: 28.r,
                    ),
                    onPressed: () => cubit.toggleFlash(),
                  ),
                Text(
                  showGalleryImage ? AppLocalizations.of(context).cameraTranslation : AppLocalizations.of(context).cameraLens,
                  style: TextStyle(
                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28.r,
                  ),
                  onPressed: showGalleryImage ? null : () => cubit.flipCamera(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  if (state.isTranslateMode)
                    _buildLanguageDropdown(
                      context: context,
                      value: state.sourceLang,
                      onChanged: (newLang) => cubit.setSourceLanguage(newLang),
                    ),
                  SizedBox(height: 8.h),
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
            padding: EdgeInsetsDirectional.only(
              bottom: 40.h,
              start: 30.w,
              end: 30.w,
            ),
            child: SizedBox(
              height: 84.h, // ensures the stack has the height of the largest element
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
                            child: SizedBox(
                              width: 50.r,
                              height: 50.r,
                              child: const Icon(
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
                                width: 84.r,
                                height: 84.r,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 4),
                                ),
                                padding: EdgeInsets.all(4.r),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 32.r,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 84.r),
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
                              width: 50.r,
                              height: 50.r,
                              child: Icon(
                                Icons.translate,
                                size: 22.r,
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
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
