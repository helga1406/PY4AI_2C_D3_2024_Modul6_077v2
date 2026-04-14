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

  double mockX = 0.5;
  double mockY = 0.5;
  String currentLabel = "D40";
  Timer? _mockTimer;

  bool isFlashOn = false;
  bool showOverlay = true;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
  }

  // --- Fungsi Toggle Senter ---
  Future<void> toggleFlash() async {
    if (controller == null || !isInitialized) return;
    try {
      isFlashOn = !isFlashOn;
      await controller!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal menyalakan senter: $e");
    }
  }

  // --- Fungsi Toggle Overlay ---
  void toggleOverlay(bool value) {
    showOverlay = value;
    notifyListeners();
  }

  // --- FUNGSI UTAMA: Inisialisasi Kamera & Simulasi ---
  Future<void> initCamera() async {
    isPermissionDenied = false;
    errorMessage = null;
    notifyListeners();

    var status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        if (cameras.isEmpty) {
          errorMessage = "Sensor kamera tidak ditemukan pada perangkat ini.";
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

        // Jalankan simulasi deteksi
        _mockTimer?.cancel();
        _mockTimer = Timer.periodic(
          const Duration(seconds: 3),
          (timer) {
            mockX = 0.2 + Random().nextDouble() * 0.6;
            mockY = 0.2 + Random().nextDouble() * 0.6;
            currentLabel = Random().nextBool() ? "D40" : "D00";
            notifyListeners();
          },
        );
      } catch (e) {
        errorMessage = "Gagal memulai sensor: $e";
      }
    } else {
      isPermissionDenied = true;
      errorMessage =
          "Akses kamera ditolak. Silakan izinkan akses untuk fitur ini.";
    }

    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (state == AppLifecycleState.resumed) {
      if (isInitialized) initCamera();
      return;
    }

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused) {
      cameraController.dispose();
      isInitialized = false;
      _mockTimer?.cancel();
      notifyListeners();
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