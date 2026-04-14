import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visionController.initCamera();
    });
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Vision Log 077",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 158, 101, 140),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) {
              if (!_visionController.isInitialized) {
                return const SizedBox.shrink();
              }
              return Switch(
                value: _visionController.showOverlay,
                activeTrackColor: const Color.fromRGBO(220, 180, 205, 1.0),
                activeThumbColor: Colors.white,
                inactiveTrackColor: const Color.fromARGB(235, 255, 252, 252),
                inactiveThumbColor: const Color.fromRGBO(220, 180, 205, 1.0),
                onChanged: _visionController.toggleOverlay,
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {

          if (!_visionController.isInitialized && 
              !_visionController.isPermissionDenied &&
              _visionController.errorMessage == null) {
            return _buildLoadingState();
          }

          // STATE ERROR: IZIN DITOLAK
          if (_visionController.isPermissionDenied) {
            return _buildPermissionDeniedState();
          }

          // STATE ERROR LAINNYA
          if (_visionController.errorMessage != null) {
            return _buildGeneralErrorState();
          }

          // STATE AKTIF (KAMERA NYALA)
          return _buildVisionStack();
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _visionController,
        builder: (context, _) {
          if (!_visionController.isInitialized) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            backgroundColor: _visionController.isFlashOn
                ? const Color.fromRGBO(158, 101, 140, 1.0)
                : Colors.white,
            onPressed: _visionController.toggleFlash,
            child: Icon(
              _visionController.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.black,
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20), 
            child: Image.asset(
              'assets/images/camera1.png',
              width: 120, 
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.camera_enhance, 
                color: Colors.red, 
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Akses Kamera Ditolak",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (_visionController.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _visionController.errorMessage!,
                textAlign: TextAlign.center, 
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 158, 101, 140),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
            onPressed: () => openAppSettings(),
            child: const Text(
              "Buka Pengaturan", 
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Lottie.asset(
            'assets/lottie/Circle grow.json', 
            width: 300, 
            fit: BoxFit.contain,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Text(
              "Menghubungkan ke Sensor Visual...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), 
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGeneralErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _visionController.errorMessage!, 
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _visionController.initCamera(),
            child: const Text(
              "Coba Lagi", 
              style: TextStyle(
                color: Color.fromARGB(255, 158, 101, 140),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / _visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),
        if (_visionController.showOverlay)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                normalizedX: _visionController.mockX,
                normalizedY: _visionController.mockY,
                label: _visionController.currentLabel,
              ),
            ),
          ),
      ],
    );
  }
}