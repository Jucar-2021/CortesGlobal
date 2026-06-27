import '../consumoPHP.dart';

class AdminApi {
  final ApiService api;
  AdminApi(this.api);

  Future<void> altaAdmin({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required int clave,
  }) async {
    try {
      final res = await api.postJson('User/admin/registrarAdmin.php', {
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'clave': clave,
      });

      if (res['ok'] != true) {
        throw Exception(res['error'] ?? 'Error desconocido al registrar administrador');
      }
    } catch (e) {
      throw Exception('Error al dar de alta al administrador: $e');
    }
  }
}
