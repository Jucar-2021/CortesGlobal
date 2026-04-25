import '../consumoPHP.dart';

class VerCorteAPI {
  final ApiService api;

  VerCorteAPI(this.api);

  Future<List<dynamic>> obtenerCortes({required String fecha}) async {
    final response = await api.postJson(
      'Consultas/Cortes/cortesDia.php',
      {'fecha': fecha},
    );

    final data = response['data'];
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<List<dynamic>> consumoClientes(
      {required String idUsuario,
      required String fecha,
      required String producto}) async {
    final response = await api.postJson(
      'Consultas/Cortes/consumoClientes.php',
      {'idUsuario': idUsuario, 'fecha': fecha, 'producto': producto},
    );

    final data = response['data'];
    if (data is List) {
      return data;
    }
    return [];
  }
}
