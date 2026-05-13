import '../consumoPHP.dart';

class RegistroRepoApi {
  final ApiService api;
  RegistroRepoApi(this.api);

  Future<void> registrarReporte({
    required String fecha,
    required int idBanco,
    required List<double> importes,
  }) async {
    await api.postJson('ReportesTarjetas/registrar.php', {
      'fecha': fecha,
      'idBanco': idBanco,
      'importes': importes,
    });
  }

  Future<void> actualizarReporte({
    required String fecha,
    required int idBanco,
    required List<double> importes,
  }) async {
    await api.postJson('ReportesTarjetas/actualizar.php', {
      'fecha': fecha,
      'idBanco': idBanco,
      'importes': importes,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerDetalle({
    required String fecha,
    required int idBanco,
  }) async {
    final res = await api.postJson('ReportesTarjetas/obtener_detalle.php', {
      'fecha': fecha,
      'idBanco': idBanco,
    });

    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception('Respuesta inesperada: "data" no es una lista');
  }

  Future<List<Map<String, dynamic>>> obtenerTotales({
    required String fecha,
    required String idBanco,
  }) async {
    final res = await api.postJson('ReportesTarjetas/obtener_totales.php', {
      'fecha': fecha,
      'idBanco': idBanco,
    });

    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception('Respuesta inesperada: "data" no es una lista');
  }
}
