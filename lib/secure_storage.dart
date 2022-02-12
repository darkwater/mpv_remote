import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

class SecureStorage {
  static Future<String?> getPasswordById(String id) async {
    return _storage.read(key: "password_$id");
  }

  static Future<void> savePassword(String id, String password) async {
    await _storage.write(key: "password_$id", value: password);
  }

  static Future<void> deletePassword(String id) async {
    await _storage.delete(key: "password_$id");
  }
}
