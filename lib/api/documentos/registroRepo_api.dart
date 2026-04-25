import '../consumoPHP.dart';

class RegistroRepoApi {
  final ApiService api;
  RegistroRepoApi(this.api);

  Future<List<Map<String, dynamic>>> obtenerTotales({
    required String fecha,
    required String banco,
  }) async {
    final res = await api.postJson('ReportesTarjetas/obtener_totales.php', {
      'fecha': fecha,
      'banco': banco,
    });

    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerDetalle({
    required String fecha,
    required String banco,
  }) async {
    final res = await api.postJson('ReportesTarjetas/obtener_detalle.php', {
      'fecha': fecha,
      'banco': banco,
    });

    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  // registro de bancos
  Future<void> registrarReporte({
    required String fecha,
    required List<double> importes,
    required String banco,
  }) async {
    await api.postJson('ReportesTarjetas/registrar.php', {
      'fecha': fecha,
      'importes': importes,
      'banco': banco,
    });
  }

  // Actualizacion de datos
  Future<void> actualizarReporte({
    required int idUsuario,
    required String fecha,
    required List<double> importes,
    required String producto,
    required String banco,
  }) async {
    await api.postJson('ReportesTarjetas/actualizar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'producto': producto,
      'importes': importes,
      'banco': banco,
    });
  }
}
