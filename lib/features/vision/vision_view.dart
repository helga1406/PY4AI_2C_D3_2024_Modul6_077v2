import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
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

          // --- MODE STATIS (Capture / Upload Galeri) ---
          if (_visionController.isUsingGallery) {
            // Cek apakah berasal dari galeri atau hasil capture instan
            bool isFromGallery = _visionController.selectedFile != null;

            return FloatingActionButton.extended(
              // Kita gunakan fungsi retakeImage yang sudah kita buat tadi
              onPressed: _visionController.retakeImage,
              backgroundColor: const Color.fromARGB(255, 158, 101, 140),
              icon: Icon(
                isFromGallery ? Icons.refresh : Icons.camera_alt,
                color: Colors.white,
              ),
              label: Text(
                isFromGallery ? "Ganti Foto" : "Ambil Ulang",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          // --- MODE LIVE (Kamera Jalan) ---
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
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Transform.scale(
                scale: _visionController.scaleFactor,
                // --- MODIFIKASI: Mendukung tampilan Kamera & Galeri ---
                child: _visionController.processedImage != null
                    ? Image.memory(
                        _visionController.processedImage!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : (_visionController.isUsingGallery
                        ? const Center(child: CircularProgressIndicator())
                        : CameraPreview(_visionController.controller!)),
              ),
            ),
          ),
        ),
        if (_visionController.isNoiseActive)
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(),
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
      width: 60,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 45, 45, 45),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Blur
            _buildToolBtn(
              Icons.blur_on,
              "blur",
              _visionController.isBlurhActive,
              _visionController.toggleBlur,
            ),
            const SizedBox(height: 16),

            // 2. Noise
            _buildToolBtn(
              Icons.grain,
              "Noise",
              _visionController.isNoiseActive,
              _visionController.toggleNoise,
            ),
            const SizedBox(height: 16),

            // 3. Capture
            _buildToolBtn(
              Icons.camera_alt,
              "Capture",
              _visionController.isUsingGallery &&
                  _visionController.selectedFile == null,
              _visionController.takeImageWithCamera,
            ),
            const SizedBox(height: 16),

            // 4. Upload
            _buildToolBtn(
              Icons.image_search,
              "Upload",
              _visionController.isUsingGallery &&
                  _visionController.selectedFile != null,
              _visionController.pickImageFromGallery,
            ),

            // PEMBATAS (Jarak disamakan)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: Colors.white10,
                thickness: 1,
                height: 0,
              ),
            ),

            // 5. Filter
            _buildToolBtn(
              Icons.tune,
              "Filter",
              _visionController.activeFilter != "Normal",
              () => _showPCDMenu(),
            ),
            const SizedBox(height: 16),

            // 6. Sharpening
            _buildToolBtn(
              Icons.shutter_speed,
              "Sharpening",
              _visionController.isSharpenActive,
              () => _visionController.toggleSharpen(),
            ),
          ],
        ),
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
                    "Brightness",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${(_visionController.brightness * 100).toInt()}%",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 220, 180, 205),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _visionController.brightness,
                min: 0.1,
                max: 2.0,
                activeColor: const Color.fromARGB(255, 158, 101, 140),
                onChanged: (val) {
                  setModalState(() {});
                  _visionController.setBrightness(val);
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
                  "Grayscale",
                  "Inverse",
                  "Threshold",
                  "Edge",
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
    return ListenableBuilder(
      listenable: _visionController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "RGB SPECTRUM",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              _buildRgbChannel(
                const Color(0xFFFF5252),
                _visionController.rData,
              ),
              const SizedBox(height: 4),
              _buildRgbChannel(
                const Color(0xFF69F0AE),
                _visionController.gData,
              ),
              const SizedBox(height: 4),
              _buildRgbChannel(
                const Color(0xFF40C4FF),
                _visionController.bData,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRgbChannel(Color color, List<double> data) {
    return SizedBox(
      width: 110,
      height: 25,
      child: CustomPaint(
        painter: HistogramPainter(
          data: data,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/camera1.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              color: Colors.white.withValues(alpha: 0.5),
              colorBlendMode: BlendMode.modulate,
            ),
            const SizedBox(height: 25),
            const Text(
              "Akses Kamera Ditolak",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Aplikasi memerlukan izin kamera untuk melakukan inspeksi PCD.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 101, 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => openAppSettings(),
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              label: const Text(
                "Buka Pengaturan",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
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

class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()..color = Colors.white.withAlpha(51);

    for (int i = 0; i < 2000; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HistogramPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  HistogramPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    double stepX = size.width / 255;

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = size.height - (data[i] * size.height).clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = Colors.white10,
    );
  }

  @override
  bool shouldRepaint(covariant HistogramPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}