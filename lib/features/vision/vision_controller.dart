import 'dart:async'; 
import 'dart:math';  
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_077/main.dart'; 

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  
  double mockX = 0.5;
  double mockY = 0.5;
  Timer? _mockTimer;

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
//
      _mockTimer?.cancel(); 
      _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        mockX = 0.2 + Random().nextDouble() * 0.6; // Menghasilkan koordinat acak
        mockY = 0.2 + Random().nextDouble() * 0.6;
        notifyListeners(); // Memicu UI untuk menggambar ulang
      });

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

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.dispose(); 
      isInitialized = false;
      _mockTimer?.cancel(); 
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera(); 
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _mockTimer?.cancel(); 
    controller?.dispose();
    super.dispose();
  }
}