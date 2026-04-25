import '../consumoPHP.dart';

class ManejocortesApi {
  final ApiService api;
  ManejocortesApi(this.api);

//valida si existe un corte registrado me diante el idUsuario y fecha,
//si existe devuelve el idCorte del corte registrado, si no existe la bd devuelve false.
  Future<int?> validarCorteRegistrado({
    required int idUsuario,
    required String fecha,
    required String producto,
  }) async {
    try {
      final res = await api.postJson('Cortes/validarExis.php', {
        'idUsuario': idUsuario,
        'fecha': fecha,
        'producto': producto,
      });

      if (res['ok'] == true && res['idCorte'] != null) {
        return res['idCorte'];
      }

      if (res['ok'] == false) {
        return null; //
      }

      throw Exception('Respuesta inesperada del servidor');
    } catch (e) {
      print('Error en validarCorteRegistrado: $e');
      rethrow;
    }
  }

  Future<void> eliminarCorte(int idCorte) async {
    try {
      await api.postJson('Cortes/eliminar.php', {
        'idCorte': idCorte,
      });
    } catch (e) {
      print('Error al eliminar corte: $e');
      throw Exception('Error al eliminar corte');
    }
  }
}
