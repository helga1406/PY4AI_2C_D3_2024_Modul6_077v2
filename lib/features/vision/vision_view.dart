import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'vision_controller.dart';

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
        title: const Text("Smart-Patrol Vision", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 158, 101, 140),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.errorMessage != null) {
            return Center(child: Text(_visionController.errorMessage!, style: const TextStyle(color: Colors.white)));
          }
          
          if (!_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator()); 
          }
          
          return Center(
            child: AspectRatio(
              aspectRatio: 1 / _visionController.controller!.value.aspectRatio, 
              child: CameraPreview(_visionController.controller!),
            ),
          );
        },
      ),
    );
  }
}