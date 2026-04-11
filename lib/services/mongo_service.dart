import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/helpers/log_helper.dart'; 

class MongoService {
  // --- SINGLETON PATTERN ---
  MongoService._internal();
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;

  Db? _db;
  final String _collectionName = "logs";
  final String _source = "mongo_service.dart";

  Db get db {
    if (_db == null) {
      throw Exception("DATABASE: Belum diinisialisasi! Panggil connect() dulu.");
    }
    return _db!;
  }

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected) {
      await LogHelper.writeLog(
        "Koneksi belum siap, mencoba menghubungkan...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _db!.collection(_collectionName);
  }

  /// Inisialisasi Koneksi
  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    try {
      final mongoUri = dotenv.env['MONGODB_URI'];
      if (mongoUri == null || mongoUri.isEmpty) {
        throw "MONGODB_URI tidak ditemukan di file .env!";
      }

      _db = await Db.create(mongoUri);
      
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw "Koneksi ke MongoDB Atlas Timeout (Cek Whitelist IP/Sinyal)";
        },
      );
      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
      
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow; 
    }
  }

// --- CRUD OPERASI DENGAN LOGHELPER ---
Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();
      
      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final result = await collection
          .find(where.eq('teamId', teamId).sortBy('date', descending: true)) 
          .toList();
      
      return result.map((e) => LogModel.fromMap(e)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow; 
    }
  }

  Future<void> insertLog(LogModel logData, String username) async {
    try {
      final collection = await _getSafeCollection();
      
      final logObjectId = ObjectId.fromHexString(logData.id!);

      await collection.updateOne(
        where.id(logObjectId),
        modify
            .set('title', logData.title)
            .set('description', logData.description)
            .set('category', logData.category)
            .set('date', logData.date)
            .set('authorId', logData.authorId)
            .set('teamId', logData.teamId)
            .set('isPublic', logData.isPublic ?? false),
        upsert: true, 
      );

      await LogHelper.writeLog(
        "SUCCESS: Data '${logData.title}' tersinkron (Upsert) ke Cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "INSERT ERROR: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLog(LogModel updatedLog, String username) async {
    try {
      final collection = await _getSafeCollection();
      if (updatedLog.id == null) throw "ID Log tidak ditemukan untuk update";

      final logObjectId = ObjectId.fromHexString(updatedLog.id!);
      await collection.updateOne(
        where.id(logObjectId), 
        modify
            .set('title', updatedLog.title)
            .set('description', updatedLog.description)
            .set('category', updatedLog.category)
            .set('date', updatedLog.date) 
            .set('teamId', updatedLog.teamId)
            .set('isPublic', updatedLog.isPublic ?? false), 
      );

      await LogHelper.writeLog(
        "DATABASE: Update '${updatedLog.title}' Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UPDATE ERROR: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> deleteLog(ObjectId logId, String username) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(
        where.id(logId) 
      );

      await LogHelper.writeLog(
        "DATABASE: Hapus ID $logId Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DELETE ERROR: $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}