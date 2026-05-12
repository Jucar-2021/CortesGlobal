import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static Future<void> guardarToken(String token) async {
    await _storage.write(
      key: "token",
      value: token,
    );
  }

  static Future<String?> obtenerToken() async {
    return await _storage.read(key: "token");
  }

  static Future<void> cerrarSesion() async {
    await _storage.delete(key: "token");
  }
}