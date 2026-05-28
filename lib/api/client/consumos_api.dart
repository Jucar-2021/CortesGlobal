import '../consumoPHP.dart';

class ConsumosApi {
  final ApiService api;
  ConsumosApi(this.api);

  Future<List<Map<String ,dynamic>>> getConsumos({required String fecha}) async {
    final res = await api.postJson('Consultas/Clientes/consumos.php', {
      'fecha': fecha,
    });
    final data = res['data'];

    if (data is List) {
      print('Consumos obtenidos: $data');
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

}