import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:logbook_app_077/features/onboarding/onboarding_view.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:camera/camera.dart'; 

List<CameraDescription> cameras = []; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: ${e.code}\nError Message: ${e.description}');
  }

  await Hive.initFlutter();

  Hive.registerAdapter(LogModelAdapter()); 

  await Hive.openBox<LogModel>('offline_logs');

  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 158, 101, 140)),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}