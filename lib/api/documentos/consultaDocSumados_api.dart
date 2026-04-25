import '../consumoPHP.dart';

class ConsultaBancosApi {
  final ApiService api;
  ConsultaBancosApi(this.api);

  Future<List<Map<String, dynamic>>> obtenerDocumentos({
    required String fechaIni,
    required String fechaFin,
  }) {
    return api.postJson('Consultas/Documentos/obtenerTarjetas.php', {
      'fechaInicio': fechaIni,
      'fechaFin': fechaFin,
    }).then((res) {
      final data = res['data'];

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Respuesta inesperada: "data" no es una lista');
      }
    });
  }

  Future<List<Map<String, dynamic>>> obtenerReportes({
    required String fechaIni,
    required String fechaFin,
  }) {
    return api.postJson('Consultas/Documentos/obtenerReportes.php', {
      'fechaInicio': fechaIni,
      'fechaFin': fechaFin,
    }).then((res) {
      final data = res['data'];

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Respuesta inesperada: "data" no es una lista');
      }
    });
  }
}
