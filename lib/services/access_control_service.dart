import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Daftar izin dasar per Role 
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionCreate, actionRead],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    if (isOwner && (action == actionUpdate || action == actionDelete)) {
      return true;
    }
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }
}