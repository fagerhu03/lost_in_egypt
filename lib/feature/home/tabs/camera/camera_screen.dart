import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'landmark_service.dart';

// ✅ Correct relative path based on your existing structure
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
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    try {
      setState(() => _isAnalyzing = true);

      final XFile imageFile = await _controller!.takePicture();
      final String? landmarkName =
      await LandmarkService.identifyLandmark(File(imageFile.path));

      if (landmarkName == null) {
        _showErrorDialog("Could not identify any landmark.");
        setState(() => _isAnalyzing = false);
        return;
      }

      await _fetchPlaceAndShowSheet(landmarkName);
    } catch (e) {
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

      if (landmarkName == null) {
        _showErrorDialog("Could not identify any landmark.");
        setState(() => _isAnalyzing = false);
        return;
      }

      await _fetchPlaceAndShowSheet(landmarkName);
    } catch (e) {
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

      // ✅ FIX: PlaceModel has fromMap (MapItem does NOT)
      final PlaceModel identifiedPlace = PlaceModel.fromMap(doc.data(), doc.id);

      setState(() => _isAnalyzing = false);
      _showResultSheet(identifiedPlace);
    } catch (e) {
      _showErrorDialog("Database error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  void _showResultSheet(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 500,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: SizedBox(
                  height: 220,
                  child: Image.network(
                    place.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
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
                      style: const TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26,
                        color: Color(0xFF4A3D2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFFE6A44A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Landmark Identified",
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      place.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // ✅ Works because PlaceModel implements MapItem
                              MapFocusService.instance.triggerFocus(place);
                            },
                            icon: const Icon(Icons.map_outlined, color: Color(0xFF4D5420)),
                            label: const Text("Show on Map",
                                style: TextStyle(color: Color(0xFF4D5420))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF4D5420)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4D5420),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Done", style: TextStyle(color: Colors.white)),
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
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE6A44A)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(_controller!),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => MapFocusService.instance.switchToTab(0),
                      ),
                      const Text(
                        "Lens",
                        style: TextStyle(fontFamily: "Marcellus", color: Colors.white, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                        onPressed: _flipCamera,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF4).withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_outlined, color: Color(0xFF4A3D2E)),
                        ),
                      ),
                      GestureDetector(
                        onTap: _captureAndAnalyze,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(color: Color(0xFFFFFDF4), shape: BoxShape.circle),
                            child: _isAnalyzing
                                ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A3D2E),
                                strokeWidth: 3,
                              ),
                            )
                                : const Icon(Icons.search, size: 36, color: Color(0xFF4A3D2E)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Found something..."),
        content: Text("We identified '$label', but currently don't have a guide for it in our database."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }
}
