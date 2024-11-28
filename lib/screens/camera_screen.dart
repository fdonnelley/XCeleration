import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> cameras;
  late CameraController controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      print('permission granted');
      _initializeCamera();
    } else {
      print("Camera permission denied");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Camera permission denied")));
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        controller = CameraController(cameras[0], ResolutionPreset.high);
        await controller.initialize();
        setState(() {
          isInitialized = true;
        });
      } else {
        print('No cameras found');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      if (!controller.value.isInitialized) return;
      final image = await controller.takePicture();
      print('Captured image: ${image.path}');
      _processImage(image.path);
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  void _processImage(String imagePath) {
    // Placeholder for OCR processing
    print('Processing image at: $imagePath');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: isInitialized
          ? Stack(
              children: [
                CameraPreview(controller),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _captureImage,
                      child: const Text('Capture Image'),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
