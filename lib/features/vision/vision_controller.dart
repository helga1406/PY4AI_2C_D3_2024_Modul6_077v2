import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_077/main.dart';
import 'package:permission_handler/permission_handler.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;
  bool isPermissionDenied = false;
  
  bool _isCameraInitializing = false; 

  double mockX = 0.5;
  double mockY = 0.5;
  String currentLabel = "D40";
  Timer? _mockTimer;

  bool isFlashOn = false;
  bool showOverlay = true;

  // --- FITUR PCD & KONTROL ---
  String activeFilter = "Normal";
  double scaleFactor = 1.0; 
  bool isSmoothActive = false; 
  bool isNoiseActive = false; 

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
  }

  void setFilter(String filterName) {
    activeFilter = filterName;
    notifyListeners();
  }

  void toggleSize() {
    scaleFactor = (scaleFactor == 1.0) ? 1.2 : 1.0;
    notifyListeners();
  }

  void toggleSmooth() {
    isSmoothActive = !isSmoothActive;
    notifyListeners();
  }

  void toggleNoise() {
    isNoiseActive = !isNoiseActive;
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (controller == null || !isInitialized) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal menyalakan senter: $e");
    }
  }

  void toggleOverlay(bool value) {
    showOverlay = value;
    notifyListeners();
  }

  // --- INISIALISASI KAMERA ---
  Future<void> initCamera() async {
    if (_isCameraInitializing) return; 
    _isCameraInitializing = true;
    
    isPermissionDenied = false;
    errorMessage = null;
    notifyListeners(); 

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      try {
        if (cameras.isEmpty) {
          errorMessage = "Sensor kamera tidak ditemukan.";
          _isCameraInitializing = false;
          notifyListeners();
          return;
        }

        final oldController = controller;
        if (oldController != null) {
          controller = null; 
          await oldController.dispose();
        }

        CameraController newController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await newController.initialize();
        controller = newController; 
        isInitialized = true;
        errorMessage = null;

        _mockTimer?.cancel();
        _mockTimer = Timer.periodic(
          const Duration(seconds: 3),
          (timer) {
            mockX = 0.2 + Random().nextDouble() * 0.6;
            mockY = 0.2 + Random().nextDouble() * 0.6;
            currentLabel = Random().nextBool() ? "D40" : "D00";
            if (isInitialized) notifyListeners();
          },
        );
      } catch (e) {
        errorMessage = "Gagal memulai sensor: $e";
      }
    } else {
      isPermissionDenied = true;
      errorMessage = "Akses kamera ditolak.";
    }

    _isCameraInitializing = false;
    notifyListeners();
  }

  // --- MANAGE LIFECYCLE ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      isInitialized = false;
      _mockTimer?.cancel();
      
      final oldController = controller;
      controller = null; 
      oldController?.dispose(); 
      
      notifyListeners();
    } 
    else if (state == AppLifecycleState.resumed) {
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