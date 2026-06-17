import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../presentation/bloc/camera_cubit.dart';
import '../presentation/bloc/camera_state.dart';

class CameraNoLandmarkView extends StatelessWidget {
  final CameraNoLandmarkFound state;
  final CameraController? controller;
  final CameraCubit cubit;

  const CameraNoLandmarkView({
    super.key,
    required this.state,
    this.controller,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (controller != null && controller!.value.isInitialized)
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(controller!),
            ),
          Center(
            child: Container(
              margin: EdgeInsets.all(24.r),
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Theme.of(context).colorScheme.primary,
                    size: 64.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    state.identifiedLabel != null
                        ? l10n.cameraNotInDb(state.identifiedLabel!)
                        : l10n.cameraNoLandmark,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => cubit.resetToReady(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(l10n.commonTryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
