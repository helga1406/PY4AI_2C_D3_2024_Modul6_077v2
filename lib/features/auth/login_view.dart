import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/auth/login_controller.dart';
import 'package:logbook_app_077/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscure = true;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    // 1. Validasi Kosong
    if (user.isEmpty || pass.isEmpty) {
      _showErrorSnackBar("Username dan Password tidak boleh kosong!");
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      String detectedRole = (user.toLowerCase() == 'admin') ? 'Ketua' : 'Anggota';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(
            username: user,
            teamId: "kelompok_077",
            role: detectedRole, 
          ),
        ),
      );
    } else {
      int sisa = 3 - _controller.attempts;
      _showErrorSnackBar("Login Gagal! Sisa percobaan: ${sisa > 0 ? sisa : 0}");
    }

    if (_controller.isLocked) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) setState(() {});
      });
    }

    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color.fromARGB(255, 158, 101, 140),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Login LogBook",
          style: TextStyle(
            color: Color.fromARGB(255, 158, 101, 140),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- IKON BESAR ---
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255,158,101,140).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded, 
                  size: 80,
                  color: Color.fromARGB(255, 158, 101, 140),
                ),
              ),
              const SizedBox(height: 40),

              // --- INPUT USERNAME DENGAN IKON ---
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color.fromARGB(255, 158, 101, 140),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 158, 101, 140),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT PASSWORD DENGAN IKON & TOGGLE VISIBILITY ---
              TextField(
                controller: _passController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color.fromARGB(255, 158, 101, 140),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 158, 101, 140),
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- TOMBOL MASUK DENGAN SHADOW ---
              ElevatedButton(
                onPressed: _controller.isLocked ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 158, 101, 140),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 5, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  _controller.isLocked ? "Terkunci (10 detik)" : "MASUK",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}