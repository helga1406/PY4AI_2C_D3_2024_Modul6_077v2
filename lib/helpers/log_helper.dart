import 'dart:io';
import 'dart:developer' as dev;
import 'package:intl/intl.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", 
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      DateTime now = DateTime.now();
      String timestamp = DateFormat('HH:mm:ss').format(now);
      String dateStr = DateFormat('dd-MM-yyyy').format(now); 
      
      String label = _getLabel(level);
      String color = _getColor(level);
      
      dev.log(message, name: source, time: now, level: level * 100);
      // ignore: avoid_print
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      String plainLogEntry = '[$timestamp][$label][$source] -> $message\n';
      await _writeToFile(dateStr, plainLogEntry);

    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static Future<void> _writeToFile(String dateStr, String logEntry) async {
    try {
      final logDirectory = Directory('logs');
      if (!await logDirectory.exists()) {
        await logDirectory.create();
      }

      final file = File('logs/$dateStr.log');

      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      dev.log("Gagal menulis ke file log: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}