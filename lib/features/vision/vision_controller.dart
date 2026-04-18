import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_077/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:image/image.dart' as img; 

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
  bool isSmoothingActive = false;
  bool isNoiseActive = false;
  double brightness = 1.0;
  bool isSharpenActive = false;

  // --- TAMBAHAN HISTOGRAM DATA ---
  List<double> rData = List.generate(256, (_) => 0.0);
  List<double> gData = List.generate(256, (_) => 0.0);
  List<double> bData = List.generate(256, (_) => 0.0);

  // --- STATE TAMBAHAN UNTUK UPLOAD IMAGE ---
  XFile? selectedFile;
  bool isUsingGallery = false;
  final ImagePicker _picker = ImagePicker();

  // --- FORMAT BARU UNTUK OPENCV & UINT8LIST ---
  bool isStreaming = false;
  bool isProcessing = false;
  Uint8List? processedImage;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
  }

  cv.Mat? capturedMat;

  // --- LOGIKA PERHITUNGAN HISTOGRAM (TAMBAHAN) ---
  void _updateHistogram(Uint8List imageBytes) {

    final image = img.decodeImage(imageBytes);
    if (image == null) return;

    var rHist = List<int>.filled(256, 0);
    var gHist = List<int>.filled(256, 0);
    var bHist = List<int>.filled(256, 0);

    // Hitung frekuensi warna
    for (var pixel in image) {
      rHist[pixel.r.toInt()]++;
      gHist[pixel.g.toInt()]++;
      bHist[pixel.b.toInt()]++;
    }

    int maxVal = [
      rHist.reduce(max),
      gHist.reduce(max),
      bHist.reduce(max),
    ].reduce(max);

    if (maxVal == 0) maxVal = 1;

    rData = rHist.map((e) => e / maxVal).toList();
    gData = gHist.map((e) => e / maxVal).toList();
    bData = bHist.map((e) => e / maxVal).toList();
  }

  // --- MENGAMBIL GAMBAR DARI KAMERA ---
  void takeImageWithCamera() {
    if (processedImage != null) {
      isUsingGallery = true;
      selectedFile = null;
      capturedMat = cv.imdecode(processedImage!, cv.IMREAD_COLOR);

      if (isStreaming) {
        controller?.stopImageStream();
        isStreaming = false;
      }
      notifyListeners();
    }
  }

  void retakeImage() {
    capturedMat?.dispose();
    capturedMat = null;
    isUsingGallery = false;
    selectedFile = null;

    if (!isStreaming && controller != null && isInitialized) {
      controller!.startImageStream((image) => _processFrame(image));
      isStreaming = true;
    }
    notifyListeners();
  }

  void _processCapturedImage() {
    if (capturedMat != null) {
      cv.Mat mat = capturedMat!.clone();
      mat = mat.convertTo(mat.type, alpha: brightness, beta: 0);
      _applyOpenCVFilters(mat);
      mat.dispose();
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedFile = image;
      isUsingGallery = true;
      if (isStreaming) {
        await controller?.stopImageStream();
        isStreaming = false;
      }
      _processStaticImage(image);
      notifyListeners();
    }
  }

  void switchToCamera() {
    isUsingGallery = false;
    selectedFile = null;
    capturedMat?.dispose();
    capturedMat = null;

    if (!isStreaming && controller != null && isInitialized) {
      controller!.startImageStream((image) => _processFrame(image));
      isStreaming = true;
    }
    notifyListeners();
  }

  void setBrightness(double value) {
    brightness = value;
    if (isUsingGallery) {
      if (selectedFile != null) {
        _processStaticImage(selectedFile!);
      } else {
        _processCapturedImage();
      }
    }
    notifyListeners();
  }

  void setFilter(String filterName) {
    activeFilter = filterName;
    if (isUsingGallery) {
      if (selectedFile != null) {
        _processStaticImage(selectedFile!);
      } else {
        _processCapturedImage();
      }
    }
    notifyListeners();
  }

  void toggleSmooth
  () {
    isSmoothingActive = !isSmoothingActive;
    if (isUsingGallery && selectedFile != null) {
      _processStaticImage(selectedFile!);
    }
    notifyListeners();
  }

  void toggleNoise() {
    isNoiseActive = !isNoiseActive;
    notifyListeners();
  }

  void toggleSharpen() {
    isSharpenActive = !isSharpenActive;
    if (isUsingGallery) {
      if (selectedFile != null) {
        _processStaticImage(selectedFile!);
      } else {
        _processCapturedImage();
      }
    }
    notifyListeners();
  }

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

  void toggleOverlay(bool value) {
    showOverlay = value;
    notifyListeners();
  }

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
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );

        await newController.initialize();
        controller = newController;
        isInitialized = true;
        errorMessage = null;

        if (!isStreaming && !isUsingGallery) {
          controller!.startImageStream((CameraImage image) {
            _processFrame(image);
          });
          isStreaming = true;
        }

        _mockTimer?.cancel();
        _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          mockX = 0.2 + Random().nextDouble() * 0.6;
          mockY = 0.2 + Random().nextDouble() * 0.6;
          currentLabel = Random().nextBool() ? "D40" : "D00";
          if (isInitialized) notifyListeners();
        });
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

  void _processStaticImage(XFile file) {
    try {
      cv.Mat mat = cv.imread(file.path);
      mat = mat.convertTo(mat.type, alpha: brightness, beta: 0);
      _applyOpenCVFilters(mat);
      mat.dispose();
    } catch (e) {
      debugPrint("Error Static Image: $e");
    }
  }

  void _processFrame(CameraImage image) {
    if (isProcessing || isUsingGallery) return;
    isProcessing = true;

    try {
      cv.Mat? mat;
      bool isBgra = image.format.group == ImageFormatGroup.bgra8888;

      if (isBgra) {
        mat = cv.Mat.fromList(
          image.height,
          image.width,
          cv.MatType.CV_8UC4,
          image.planes[0].bytes,
        );
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        Uint8List yBytes = image.planes[0].bytes;
        Uint8List vuBytes = image.planes[2].bytes;
        Uint8List nv21Bytes = Uint8List(yBytes.length + vuBytes.length);
        nv21Bytes.setAll(0, yBytes);
        nv21Bytes.setAll(yBytes.length, vuBytes);

        cv.Mat yuvMat = cv.Mat.fromList(
          image.height + (image.height ~/ 2),
          image.width,
          cv.MatType.CV_8UC1,
          nv21Bytes,
        );
        mat = cv.cvtColor(yuvMat, cv.COLOR_YUV2BGR_NV21);
        yuvMat.dispose();
      }

      if (mat != null) {
        mat = cv.rotate(mat, cv.ROTATE_90_CLOCKWISE);
        mat = mat.convertTo(mat.type, alpha: brightness, beta: 0);

        _applyOpenCVFilters(mat);
        mat.dispose();
      }
    } catch (e) {
      debugPrint("Error Live Processing: $e");
    } finally {
      isProcessing = false;
    }
  }

  void _applyOpenCVFilters(cv.Mat sourceMat) {
    cv.Mat resultMat = sourceMat.clone();
    bool isBgra = sourceMat.channels == 4;

    switch (activeFilter) {
      case "Grayscale":
        resultMat = isBgra
            ? cv.cvtColor(sourceMat, cv.COLOR_BGRA2GRAY)
            : cv.cvtColor(sourceMat, cv.COLOR_BGR2GRAY);
        break;
      case "Threshold":
        cv.Mat grayMat = isBgra
            ? cv.cvtColor(sourceMat, cv.COLOR_BGRA2GRAY)
            : cv.cvtColor(sourceMat, cv.COLOR_BGR2GRAY);
        resultMat = cv.threshold(grayMat, 100, 255, cv.THRESH_BINARY).$2;
        grayMat.dispose();
        break;
      case "High-pass":
        cv.Mat smoothMat = cv.gaussianBlur(sourceMat, (7, 7), 0);
        resultMat = cv.subtract(sourceMat, smoothMat); 
        smoothMat.dispose();
      break;
      case "Inverse":
        resultMat = cv.bitwiseNOT(sourceMat);
        break;
      case "XOR":
        cv.Mat edge = cv.canny(sourceMat, 50, 150);
        // Mengubah edge (1 channel) ke format yang sama dengan sourceMat (3/4 channel)
        cv.Mat edgeConverted = cv.cvtColor(edge, cv.COLOR_GRAY2BGR); 
        resultMat = cv.bitwiseXOR(sourceMat, edgeConverted);
        edge.dispose();
        edgeConverted.dispose();
      break;
      case "Dilation":
        final rect = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
        resultMat = cv.dilate(sourceMat, rect);
        break;
      case "Erosion":
        final rect = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
        resultMat = cv.erode(sourceMat, rect);
        break;
      case "Edge":
        cv.Mat edgeGray = isBgra
            ? cv.cvtColor(sourceMat, cv.COLOR_BGRA2GRAY)
            : cv.cvtColor(sourceMat, cv.COLOR_BGR2GRAY);
        cv.Mat blurred = cv.gaussianBlur(edgeGray, (5, 5), 0);
        resultMat = cv.canny(blurred, 40, 60);
        edgeGray.dispose();
        blurred.dispose();
        break;
      default:
        break;
    }

    if (isSharpenActive) {
      cv.Mat tempBlur = cv.gaussianBlur(resultMat, (5, 5), 1.5);
      resultMat = cv.addWeighted(resultMat, 1.5, tempBlur, -0.5, 0);
      tempBlur.dispose();
    }

    if (isSmoothingActive) {
      resultMat = cv.gaussianBlur(resultMat, (5, 5), 0);
    }

    processedImage = cv.imencode('.jpg', resultMat).$2;

    if (processedImage != null) {
      _updateHistogram(processedImage!);
    }

    resultMat.dispose();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      isInitialized = false;
      isStreaming = false;
      _mockTimer?.cancel();

      final oldController = controller;
      controller = null;
      oldController?.dispose();

      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mockTimer?.cancel();
    controller?.stopImageStream();
    controller?.dispose();
    super.dispose();
  }
}