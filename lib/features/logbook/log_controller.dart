import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logbook_app_077/services/access_control_service.dart';
import 'package:logbook_app_077/helpers/log_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LogController {
  // --- STATE UI ---
  final ValueNotifier<String> searchQuery = ValueNotifier("");
  final ValueNotifier<String> selectedFilter = ValueNotifier("Semua");
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  final String username;
  final String userRole;
  final String teamId; 

  late final Box<LogModel> _myBox;

  LogController({
    required this.username,
    required this.teamId, 
    this.userRole = 'Anggota',
  }) {
    _myBox = Hive.box<LogModel>('offline_logs');

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        _syncPendingData();
      }
    });
  }

  void _refreshUI() {
    final localData = _myBox.values.where((log) => log.teamId == teamId).toList();
    logsNotifier.value = _applyPrivacyFilter(localData);
  }

  // --- FILTER PRIVASI ---
  List<LogModel> _applyPrivacyFilter(List<LogModel> allLogs) {
    return allLogs.where((log) {
      bool isMyOwnLog = log.authorId.trim().toLowerCase() == 
          username.trim().toLowerCase();
      bool isPublicLog = (log.isPublic ?? false) == true;

      return isMyOwnLog || isPublicLog;
    }).toList();
  }

  // --- SINKRONISASI DATA (BACKGROUND) ---
  Future<void> _syncPendingData() async {
    await LogHelper.writeLog("INTERNET AKTIF: Memulai sinkronisasi...", level: 2);

    final pendingLogs = _myBox.values.where((l) => l.id != null && l.id!.contains('temp-')).toList();
    
    for (var tempLog in pendingLogs) {
      try {
        bool isOwner = tempLog.authorId.trim().toLowerCase() == username.trim().toLowerCase();
        
        if (isOwner) {
          final realId = tempLog.id!.replaceAll('temp-', '');
          final cloudLog = tempLog.copyWith(id: realId);

          await MongoService().insertLog(cloudLog, username);
          await _myBox.delete(tempLog.id);
          await _myBox.put(cloudLog.id, cloudLog);
        }
      } catch (e) {
        await LogHelper.writeLog("ERROR: Sinkronisasi gagal log ${tempLog.id}", level: 1);
      }
    }
    _refreshUI(); 
  }

  void searchLog(String query) {
    searchQuery.value = query;
    _refreshUI();
  }

  void setFilterCategory(String category) {
    selectedFilter.value = category;
    _refreshUI();
  }

  // --- FUNGSI LOAD LOGS ---
  Future<void> loadLogs(String teamId) async {
    _refreshUI(); 

    try {
      await _syncPendingData(); 
      final cloudData = await MongoService().getLogs(teamId);

      for (var item in cloudData) {
        if (item.id != null) {
          bool isMyOwn = item.authorId.trim().toLowerCase() == username.trim().toLowerCase();
          bool isPublic = (item.isPublic ?? false) == true;

          if (isMyOwn || isPublic) {
            await _myBox.put(item.id, item); 
          }
        }
      }
      
      _refreshUI(); 
      await LogHelper.writeLog("SYNC: Data sinkron dengan Cloud", level: 2);
      
    } catch (e) {
      await LogHelper.writeLog("OFFLINE MODE: Menampilkan data lokal (Error: $e)", level: 2);
    }
  }

  // --- FUNGSI ADD LOG ---
  Future<void> addLog(
      String title, 
      String desc, 
      String category, {
      required bool isPublic,
    }) async {
      // Validasi RBAC
      if (!AccessControlService.canPerform(userRole, AccessControlService.actionCreate)) {
        await LogHelper.writeLog("SECURITY BREACH: Unauthorized create", level: 1);
        return;
      }

      final String formattedTime = DateTime.now().toString().substring(0, 16);
      final String realId = mongo.ObjectId().oid; 
      
      final newLogTemp = LogModel(
        id: "temp-$realId", 
        title: title,
        description: desc,
        date: formattedTime,
        authorId: username.trim().toLowerCase(),
        teamId: teamId,
        category: category,
        isPublic: isPublic,
      );

      await _myBox.put(newLogTemp.id, newLogTemp);
      _refreshUI();

      try {
        final cloudLog = newLogTemp.copyWith(id: realId); 
        await MongoService().insertLog(cloudLog, username);
        await _myBox.delete(newLogTemp.id);
        await _myBox.put(cloudLog.id, cloudLog);
        _refreshUI();
      } catch (e) {
        await LogHelper.writeLog("WARNING: Data tersimpan lokal (Offline)", level: 1);
      }
    }

  // --- FUNGSI UPDATE LOG ---
  Future<void> updateLog(LogModel updatedLog) async {
    final originalLog = _myBox.get(updatedLog.id);
    bool isOwner = (originalLog?.authorId.trim().toLowerCase() ??
            updatedLog.authorId.trim().toLowerCase()) ==
        username.trim().toLowerCase();

    if (!AccessControlService.canPerform(userRole, AccessControlService.actionUpdate, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized update", level: 1);
      return;
    }

    await _myBox.put(updatedLog.id, updatedLog);
    _refreshUI();

    try {
      await MongoService().updateLog(updatedLog, username);
    } catch (e) {
      await LogHelper.writeLog("WARNING: Update tersimpan lokal", level: 1);
    }
  }

  // --- FUNGSI REMOVE LOG ---
  Future<void> removeLog(LogModel log) async {
    bool isOwner = log.authorId.trim().toLowerCase() == username.trim().toLowerCase();

    if (!AccessControlService.canPerform(userRole, AccessControlService.actionDelete, isOwner: isOwner)) {
      await LogHelper.writeLog("SECURITY BREACH: Unauthorized delete", level: 1);
      return;
    }

    if (log.id != null) {
      await _myBox.delete(log.id);
      _refreshUI();

      try {
        if (!log.id!.contains('temp-')) {
          final objectId = mongo.ObjectId.fromHexString(log.id!);
          await MongoService().deleteLog(objectId, username);
        }
      } catch (e) {
        await LogHelper.writeLog("WARNING: Gagal hapus di Cloud", level: 1);
      }
    }
  }

  Future<void> clearLocalData() async => await _myBox.clear();
}