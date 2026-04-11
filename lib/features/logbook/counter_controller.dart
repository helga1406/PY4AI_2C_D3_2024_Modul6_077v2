import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1; 
  List<String> _history = []; 

  int get value => _counter;
  int get step => _step;
  List<String> get history => _history;

  void setStep(int s) => _step = s;

  // 1. Fungsi Memuat Data (Persistence)
  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt('${username}_counter') ?? 0;
    _history = prefs.getStringList('${username}_history') ?? [];
  }

  // 2. Fungsi Menyimpan Data
  Future<void> _saveData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${username}_counter', _counter);
    await prefs.setStringList('${username}_history', _history);
  }

  // --- LOGIKA RIWAYAT ---
  void _addHistory(String username, String aksi) {
    DateTime now = DateTime.now();
    String jam = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    String pesan = "User $username $aksi pada jam $jam";

    _history.insert(0, pesan);
    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  // --- LOGIKA TOMBOL---
  Future<void> increment(String username) async {
    _counter += _step;
    _addHistory(username, "menambah +$_step");
    await _saveData(username);
  }

  Future<void> decrement(String username) async {
    if (_counter > 0) {
      _counter -= _step;
      _addHistory(username, "mengurangi -$_step");
      await _saveData(username);
    }
  }

  Future<void> reset(String username) async {
    _counter = 0;
    _addHistory(username, "me-reset data");
    await _saveData(username);
  }
}