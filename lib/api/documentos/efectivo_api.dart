import '../consumoPHP.dart';

class ConsultaEfectivoApi {
  final ApiService api;
  ConsultaEfectivoApi(this.api);

  Future<List<Map<String, dynamic>>> obtenerBuzon({
    required String fechaIni,
    required String fechaFin,
  }) {
    return api
        .postJson('Consultas/Documentos/obtenerBuzon.php', {
      'fechaInicio': fechaIni,
      'fechaFin': fechaFin,
    })
        .then((res) {

      if (res['ok'] != true) {
        throw Exception(
          res['error'] ?? 'Error al obtener datos del buzón',
        );
      }

      final data = res['registros'];

      if (data is List) {
        print('Datos del buzón obtenidos: $data');
        return data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        throw Exception(
          'Respuesta inesperada: "registros" no es una lista',
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> obtenerCajero({
    required String fechaIni,
    required String fechaFin,
  }) {
    return api
        .postJson('Consultas/Documentos/obtenerCajero.php', {
      'fechaInicio': fechaIni,
      'fechaFin': fechaFin,
    })
        .then((res) {

      if (res['ok'] != true) {
        throw Exception(
          res['error'] ?? 'Error al obtener datos del cajero',
        );
      }

      final data = res['registros'];

      if (data is List) {
        print('Datos del buzón obtenidos: $data');
        return data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        throw Exception(
          'Respuesta inesperada: "registros" no es una lista',
        );
      }
    });
  }
  }

