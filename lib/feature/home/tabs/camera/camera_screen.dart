import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'landmark_service.dart';
import '../home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/services/map_focus_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _onNewCameraSelected(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final previous = _controller;

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
      Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    await previous?.dispose();

    if (mounted) setState(() => _controller = controller);

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }

    if (!mounted) return;
    setState(() => _isCameraInitialized = _controller!.value.isInitialized);
  }

  void _flipCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    _onNewCameraSelected(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isAnalyzing) return;

    try {
      setState(() => _isAnalyzing = true);

      final XFile imageFile = await _controller!.takePicture();
      final String? landmarkName =
      await LandmarkService.identifyLandmark(File(imageFile.path));

      if (!mounted) return;

      if (landmarkName == null) {
        _showErrorDialog("Could not identify any landmark.");
        setState(() => _isAnalyzing = false);
        return;
      }

      await _fetchPlaceAndShowSheet(landmarkName);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      final String? landmarkName =
      await LandmarkService.identifyLandmark(File(image.path));

      if (!mounted) return;

      if (landmarkName == null) {
        _showErrorDialog("Could not identify any landmark.");
        setState(() => _isAnalyzing = false);
        return;
      }

      await _fetchPlaceAndShowSheet(landmarkName);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _fetchPlaceAndShowSheet(String placeName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('title', isEqualTo: placeName)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        _showNoMatchDialog(placeName);
        setState(() => _isAnalyzing = false);
        return;
      }

      final doc = snapshot.docs.first;
      final PlaceModel identifiedPlace = PlaceModel.fromMap(doc.data(), doc.id);

      setState(() => _isAnalyzing = false);
      _showResultSheet(identifiedPlace);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Database error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  void _showResultSheet(PlaceModel place) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    final sheetShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.12),
      blurRadius: 22,
      spreadRadius: 2,
      offset: const Offset(0, -6),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 520,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: borderColor),
            boxShadow: [sheetShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
                child: SizedBox(
                  height: 220,
                  child: Image.network(
                    place.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26,
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Landmark Identified",
                          style: TextStyle(
                            color: onSurface.withOpacity(0.75),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      place.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: onSurface.withOpacity(0.70)),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              MapFocusService.instance.triggerFocus(place);
                            },
                            icon: Icon(Icons.map_outlined, color: primary),
                            label: Text(
                              "Show on Map",
                              style: TextStyle(color: primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Done",
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!_isCameraInitialized || _controller == null) {
      return Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    // Camera UI stays dark by design
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(_controller!),
          ),

          // subtle vignette for better readability
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => MapFocusService.instance.switchToTab(0),
                      ),
                      const Text(
                        "Lens",
                        style: TextStyle(
                          fontFamily: "Marcellus",
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios,
                            color: Colors.white, size: 28),
                        onPressed: _flipCamera,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                Padding(
                  padding:
                  const EdgeInsets.only(bottom: 40, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(Icons.photo_library_outlined,
                              color: theme.colorScheme.onSurface),
                        ),
                      ),

                      // Capture + Analyze
                      GestureDetector(
                        onTap: _captureAndAnalyze,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _isAnalyzing
                                ? Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: CircularProgressIndicator(
                                color: primary,
                                strokeWidth: 3,
                              ),
                            )
                                : Icon(Icons.search,
                                size: 36, color: primary),
                          ),
                        ),
                      ),

                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNoMatchDialog(String label) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        title: Text("Found something...", style: TextStyle(color: onSurface)),
        content: Text(
          "We identified '$label', but currently don't have a guide for it in our database.",
          style: TextStyle(color: onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK", style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        title: Text("Error", style: TextStyle(color: onSurface)),
        content: Text(msg, style: TextStyle(color: onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK", style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }
}