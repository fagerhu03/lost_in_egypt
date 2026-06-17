import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../presentation/bloc/camera_cubit.dart';
import '../presentation/bloc/camera_state.dart';

class CameraErrorView extends StatelessWidget {
  final CameraError state;
  final CameraCubit cubit;

  const CameraErrorView({
    super.key,
    required this.state,
    required this.cubit,
  });

  String _detail(AppLocalizations l10n) {
    switch (state.kind) {
      case CameraErrorKind.noCameras:
        return l10n.cameraErrNoCameras;
      case CameraErrorKind.initFailed:
        return l10n.cameraErrInitFailed;
      case CameraErrorKind.translationModelsFailed:
        return l10n.cameraErrTranslationModels;
      case CameraErrorKind.languageModelFailed:
        return l10n.cameraErrLanguageModel;
      case CameraErrorKind.noTextFound:
        return l10n.cameraErrNoText;
      case null:
        return state.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isApiKeyError ? Icons.key_off : Icons.error_outline,
                  color: Colors.red,
                  size: 64.r,
                ),
                SizedBox(height: 16.h),
                Text(
                  state.isApiKeyError ? l10n.cameraConfigError : l10n.cameraErrorTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _detail(l10n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => cubit.resetToReady(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6A44A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                      ),
                      child: Text(l10n.commonTryAgain, style: TextStyle(fontSize: 16.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
