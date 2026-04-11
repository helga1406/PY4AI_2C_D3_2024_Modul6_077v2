import 'dart:io';
import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_077/services/mongo_service.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  test('Verifikasi Koneksi MongoDB Atlas via MongoService', () async {
    final mongoService = MongoService();
    
    log("--- START CONNECTION TEST ---", name: "TEST");

    try {
      final uri = dotenv.env['MONGODB_URI'];
      expect(uri, isNotNull, reason: "MONGODB_URI tidak ditemukan di .env");

      await mongoService.connect();

      expect(mongoService.db.isConnected, true);
      
      log("SUCCESS: Koneksi Atlas Terverifikasi", name: "TEST");

    } catch (e) {
      log("ERROR: Kegagalan koneksi - $e", name: "TEST", error: e);
      fail("Koneksi gagal: $e");
    } finally {
      await mongoService.close();
      log("--- END TEST ---", name: "TEST");
    }
  });
}