import '../consumoPHP.dart';

class UserApi {
  final ApiService api;
  UserApi(this.api);

  Future<bool> registrarUsuario(String usuario, String pass, String nombre,
      String apellidoPaterno, String apellidoMaterno) async {
    await api.postJson('User/registrar.php', {
      'usuario': usuario,
      'pass': pass,
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
    });
    return true; // si postJson no lanza excepción, fue ok
  }

  Future<Map<String, dynamic>?> validarUsuario(
      String usuario, String pass) async {
    try {
      final res = await api.postJson('User/validar.php', {
        'usuario': usuario,
        'pass': pass,
      });

      if (res['ok'] == true) {
        return res;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> validarAdmin(int clave) async {
    try {
      final res = await api.postJson('User/validarAdmin.php', {
        'clave': clave,
      });

      if (res['ok'] == true) {
        return res;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
