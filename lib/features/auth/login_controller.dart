import 'dart:async'; 

class LoginController {
  final Map<String, String> _users = {
    "admin": "123",
    "helga": "polban2026",
  };

  int _loginAttempts = 0;
  bool _isWaiting = false; 

  bool login(String username, String password) {

    if (_isWaiting) return false;

    if (_users.containsKey(username) && _users[username] == password) {
      _loginAttempts = 0;
      return true;
    }

    _loginAttempts++;

    if (_loginAttempts >= 3) {
      _isWaiting = true; 
      Future.delayed(const Duration(seconds: 10), () {
        _loginAttempts = 0;
        _isWaiting = false; 
      });
    }
    
    return false;
  }

  int get attempts => _loginAttempts;
  bool get isLocked => _loginAttempts >= 3;
}
