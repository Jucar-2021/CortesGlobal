import '../consumoPHP.dart';

class DocuementosApi {
  final ApiService api;
  DocuementosApi(this.api);

  Future<List<Map<String, dynamic>>> getBancos() async {
    final res = await api.postJson('TarjetasCajero/listar.php', {});
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerDatos({
    required int idUsuario,
    required String fecha,
    required String turno,
    required String banco,
    int? idbanco,
  }) async {
    final res = await api.postJson('TarjetasCajero/obtener.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'banco': banco,
      'idbanco': idbanco,
    });

    final data = res['data'];
print(data);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  // registro de bancos
  Future<void> registrarDatos({
    required int idUsuario,
    required String fecha,
    required List<double> importes,
    required String turno,
    required String banco,
  }) async {
    await api.postJson('TarjetasCajero/registrar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'importes': importes,
      'banco': banco,
    });
  }

  // Actualizacion de datos
  Future<void> actualizarDatos({
    required int idUsuario,
    required String fecha,
    required List<double> importes,
    required String turno,
    required String banco,
  }) async {
    await api.postJson('TarjetasCajero/actualizar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'importes': importes,
      'banco': banco,
    });
  }

  // Eliminacion de datos
  Future<void> eliminarDatos({required int id, required String banco}) async {
    print('Eliminando tarjeta TarjetasCajero con id: $id');
    print(' Banco: $banco');
    await api.postJson('TarjetasCajero/eliminar.php', {
      'id': id,
      'banco': banco,
    });
  }
}
