import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_077/main.dart';  

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  
  VisionController() {
    WidgetsBinding.instance.addObserver(this); 
    initCamera();
  }
  Future<void> initCamera() async {
    try {
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device."; 
        notifyListeners();
        return;
      }
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, 
        enableAudio: false, 
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;

    } catch (e) {
      errorMessage = "Failed to initialize camera: $e"; 
    }
    notifyListeners();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return; 
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose(); 
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera(); // Inisialisasi ulang
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    controller?.dispose();
    super.dispose();
  }
}