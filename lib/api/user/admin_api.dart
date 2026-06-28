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
        throw Exception(
          res['error'] ?? 'Error desconocido al registrar administrador',
        );
      }
    } catch (e) {
      throw Exception('Error al dar de alta al administrador: $e');
    }
  }

  Future<void> estadoAdmin({
    required int idAdministrador,
    required int estado,
  }) async {
    try {
      final res = await api.postJson('User/admin/estado.php', {
        'idAdministrador': idAdministrador,
        'estado': estado,
      });

      if (res['ok'] != true) {
        throw Exception(
          res['error'] ??
              'Error desconocido al actualizar el estado del administrador',
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar el estado del administrador: $e');
    }
  }

  Future<List<Map<String, dynamic>>> listarAdmins() async {
    try {
      final res = await api.postJson('User/admin/listarAdmins.php', {});

      if (res['ok'] != true) {
        throw Exception(
          res['error'] ?? 'Error desconocido al obtener administradores',
        );
      }

      final data = res['data'];
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error al obtener la lista de administradores: $e');
    }
  }

  Future<void> cambiarClave({
    required int idAdministrador,
    required int nuevaClave,
  }) async {
    try {
      final res = await api.postJson('User/admin/cambiarClave.php', {
        'idAdministrador': idAdministrador,
        'clave': nuevaClave,
      });

      if (res['ok'] != true) {
        throw Exception(
          res['error'] ?? 'Error desconocido al cambiar la clave',
        );
      }
    } catch (e) {
      throw Exception('Error al cambiar la clave del administrador: $e');
    }
  }
}
