import '../consumoPHP.dart';

class GenetalTPVapi {
  final ApiService api;
  GenetalTPVapi(this.api);

  Future<List<Map<String, dynamic>>> getCobrosTPV({
    required String fecha,
  }) async {
    final res = await api.postJson('Consultas/CobrosTPV/listar.php', {
      'fecha': fecha,
    });
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<void> actualizarBanco({
    required int idCobro,
    required int idBancoNuevo,
  }) async {
    try {
      print('Enviando solicitud para actualizar banco del cobro $idCobro al banco $idBancoNuevo');
      final res = await api.postJson(
        'Consultas/CobrosTPV/actualizarBanco.php',
        {
          'idCobro': idCobro,
          'idNuevoBanco': idBancoNuevo,
        },
      );

      if (res['ok'] == true) {
        print('Banco actualizado correctamente');
      } else {
        print('Error al actualizar el banco: ${res['error']}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }

  Future<void> actualizarImporte({
    required int idCobro,
    required double nuevoImporte,
  }) async {
    try {
      final res = await api.postJson(
        'Consultas/CobrosTPV/actualizarImporte.php',
        {'idCobro': idCobro, 'nuevoImporte': nuevoImporte},
      );
      if (res['success'] == true) {
        print('Importe actualizado correctamente');
      } else {
        print('Error al actualizar el importe: ${res['message']}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }

  Future<void> eliminarCobro({required int idCobro}) async {
    try {
      final res = await api.postJson('Consultas/CobrosTPV/eliminarCobro.php', {
        'idCobro': idCobro,
      });
      if (res['success'] == true) {
        print('Cobro eliminado correctamente');
      } else {
        print('Error al eliminar el cobro: ${res['message']}');
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }
}
