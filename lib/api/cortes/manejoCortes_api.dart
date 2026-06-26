import '../consumoPHP.dart';

class ManejocortesApi {
  final ApiService api;
  ManejocortesApi(this.api);

  //valida si existe un corte registrado me diante el idUsuario y fecha,
  //si existe devuelve el idCorte del corte registrado, si no existe la bd devuelve false.
  Future<int?> validarCorteRegistrado({
    required int idUsuario,
    required String fecha,
    required String turno,
  }) async {
    try {
      final res = await api.postJson('Cortes/validarExis.php', {
        'idUsuario': idUsuario,
        'fecha': fecha,
        'turno': turno,
      });

      print('Respuesta validar corte: $res');

      if (res['ok'] == true && res['idCorte'] != null) {
        return int.tryParse(res['idCorte'].toString());
      }

      return null;
    } catch (e) {
      print('Error en validarCorteRegistrado: $e');
      return null;
    }
  }

  Future<void> eliminarCorte(int idCorte) async {
    try {
      await api.postJson('Cortes/eliminar.php', {'idCorte': idCorte});
    } catch (e) {
      print('Error al eliminar corte: $e');
      throw Exception('Error al eliminar corte');
    }
  }

  Future<void> actualizarCorte({
    required int idCorte,
    required double venta,
    required double cobros_tpv,
    required double clientes,
    required double cajero,
    required double buzon,
    required double gastos,
  }) async {
    try {
      await api.postJson('Cortes/actualizar.php', {
        'idCorte': idCorte,
        'venta': venta,
        'cobros_tpv': cobros_tpv,
        'clientes': clientes,
        'cajero': cajero,
        'buzon': buzon,
        'gastos': gastos,
      });
    } catch (e) {
      print('Error al actualizar corte: $e');
      throw Exception('Error al actualizar corte');
    }
  }
}
