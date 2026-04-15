import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'dart:ui'; 
import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> with TickerProviderStateMixin {
  late VisionController _visionController;
  late AnimationController _histogramController;
  double _intensity = 1.0;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();

    _histogramController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visionController.initCamera();
    });
  }

  @override
  void dispose() {
    _visionController.dispose();
    _histogramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PCD Inspector 077",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 4,
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
                activeThumbColor: Colors.white,
                activeTrackColor: const Color.fromARGB(255, 220, 180, 205),
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

          if (_visionController.isPermissionDenied) {
            return _buildPermissionDeniedState();
          }

          if (_visionController.errorMessage != null) {
            return _buildGeneralErrorState();
          }

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
            mini: true,
            backgroundColor: _visionController.isFlashOn
                ? const Color.fromARGB(255, 158, 101, 140)
                : const Color(0xFF2D2D2D),
            onPressed: _visionController.toggleFlash,
            child: Icon(
              _visionController.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisionStack() {
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: _visionController.scaleFactor,
            child: ColorFiltered(
              colorFilter: _getPCDFilter(
                _visionController.activeFilter,
                _intensity,
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _visionController.isSmoothActive ? 5.0 : 0.0,
                  sigmaY: _visionController.isSmoothActive ? 5.0 : 0.0,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_visionController.controller!),
                    if (_visionController.isNoiseActive)
                      CustomPaint(
                        painter: NoisePainter(),
                      ),
                  ],
                ),
              ),
            ),
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
        Positioned(
          right: 15,
          top: 20,
          child: _buildSidebarTools(),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: _buildLiveHistogram(),
        ),
      ],
    );
  }

  Widget _buildSidebarTools() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 45, 45, 45),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToolBtn(
            Icons.zoom_in,
            "Size",
            _visionController.scaleFactor > 1.0,
            _visionController.toggleSize,
          ),
          const SizedBox(height: 20), 
          _buildToolBtn(
            Icons.blur_on,
            "Smooth",
            _visionController.isSmoothActive,
            _visionController.toggleSmooth,
          ),
          const SizedBox(height: 20), 
          _buildToolBtn(
            Icons.grain,
            "Noise",
            _visionController.isNoiseActive,
            _visionController.toggleNoise,
          ),
          
          const SizedBox(height: 10), 
          const Divider(
            color: Colors.white10, 
            height: 1,      
            thickness: 1,
          ),
          const SizedBox(height: 9), 
          
          _buildToolBtn(
            Icons.tune,
            "Filter",
            _visionController.activeFilter != "Normal",
            () => _showPCDMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(
    IconData icon,
    String label,
    bool active,
    VoidCallback tap,
  ) {
    return GestureDetector(
      onTap: tap,
      child: Column(
        children: [
          Icon(
            icon,
            color: active
                ? const Color.fromARGB(255, 158, 101, 140)
                : Colors.white60,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color.fromARGB(255, 220, 180, 205)
                  : const Color(0xFFB0B0B0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showPCDMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "PCD Controls",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Intensity",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${(_intensity * 100).toInt()}%",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 220, 180, 205),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _intensity,
                min: 0.1,
                max: 2.0,
                activeColor: const Color.fromARGB(255, 158, 101, 140),
                onChanged: (val) {
                  setModalState(() => _intensity = val);
                  setState(() => _intensity = val);
                },
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  "Normal",
                  "Kontras",
                  "Grayscale",
                  "Invert",
                  "Sepia",
                  "Threshold", 
                ].map((f) {
                  bool sel = _visionController.activeFilter == f;
                  return ActionChip(
                    label: Text(f),
                    onPressed: () {
                      _visionController.setFilter(f);
                      Navigator.pop(context);
                    },
                    backgroundColor: sel
                        ? const Color.fromARGB(255, 158, 101, 140)
                        : Colors.white,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: sel ? Colors.transparent : Colors.black12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHistogram() {
    return AnimatedBuilder(
      animation: _histogramController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 45, 45, 45).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
              ),
            ],
          ),

          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildRgbChannel(Colors.redAccent, 0.0),     
              _buildRgbChannel(Colors.greenAccent, 1.0),   
              _buildRgbChannel(Colors.lightBlueAccent, 2.0), 
            ],
          ),
        );
      },
    );
  }

  // --- Helper method untuk membangun channel histogram RGB ---
  Widget _buildRgbChannel(Color color, double phaseShift) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(8, (i) {

        double wave = sin((_histogramController.value * pi) + (i * 0.8) + phaseShift);
        
        double h = (wave * 12 + 25) * _intensity;

        return Container(
          width: 6,
          height: h.clamp(5, 50),
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(3),
            ),

            color: color.withValues(alpha: 0.5), 
          ),
        );
      }),
    );
  }

  // --- Helper method untuk mendapatkan ColorFilter ---
  ColorFilter _getPCDFilter(String filter, double val) {
    switch (filter) {
      case "Kontras":
        double offset = -50 * val;
        return ColorFilter.matrix([
          val, 0, 0, 0, offset,
          0, val, 0, 0, offset,
          0, 0, val, 0, offset,
          0, 0, 0, 1, 0,
        ]);
      case "Grayscale":
        return const ColorFilter.matrix([
          0.21, 0.72, 0.07, 0, 0,
          0.21, 0.72, 0.07, 0, 0,
          0.21, 0.72, 0.07, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case "Invert":
        return const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]);
      case "Sepia":
        return const ColorFilter.matrix([
          0.39, 0.76, 0.18, 0, 0,
          0.34, 0.68, 0.16, 0, 0,
          0.27, 0.53, 0.13, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case "Threshold":

        double t = 100.0; 
        return ColorFilter.matrix([
          t * 0.21, t * 0.72, t * 0.07, 0, -128 * t,
          t * 0.21, t * 0.72, t * 0.07, 0, -128 * t,
          t * 0.21, t * 0.72, t * 0.07, 0, -128 * t,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(
          Colors.transparent,
          BlendMode.multiply,
        );
    }
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 25),
          const Text(
            "Akses Kamera Ditolak",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 158, 101, 140),
            ),
            onPressed: () => openAppSettings(),
            child: const Text("Buka Pengaturan"),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/Circle grow.json',
            width: 250,
            fit: BoxFit.contain,
          ),
          const Text(
            "Menghubungkan ke Sensor Visual...",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 150),
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
            _visionController.errorMessage ?? "Error",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _visionController.initCamera(),
            child: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }
}

// --- CustomPainter untuk efek noise statis ---
class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.2);

    for (int i = 0; i < 2000; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}