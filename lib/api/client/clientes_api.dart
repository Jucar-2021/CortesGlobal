import '../consumoPHP.dart';

class ClientesApi {
  final ApiService api;
  ClientesApi(this.api);

  Future<List<Map<String, dynamic>>> getClientes() async {
    final res = await api.postJson('Clientes/listar.php', {});
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<List<Map<String, dynamic>>> getClienteconsumo({
    required int idCliente,
    required int idUsuario,
    required String fecha,
    required String producto,
  }) async {
    final res = await api.postJson('Clientes/obtener.php', {
      'idCliente': idCliente,
      'idUsuario': idUsuario,
      'fecha': fecha,
      'producto': producto,
    });

    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<void> registrarClientes({
    required int idUsuario,
    required int idCliente,
    required String razonSocial,
    required String fecha,
    required List<double> importes,
    required String producto,
  }) async {
    await api.postJson('Clientes/registrar.php', {
      'idUsuario': idUsuario,
      'idCliente': idCliente,
      'razonSocial': razonSocial,
      'fecha': fecha,
      'importes': importes,
      'producto': producto,
    });
  }

  Future<void> actualizarClientes({
    required int idUsuario,
    required int idCliente,
    required String razonSocial,
    required String fecha,
    required List<double> importes,
    required String producto,
  }) async {
    await api.postJson('Clientes/actualizar.php', {
      'idUsuario': idUsuario,
      'idCliente': idCliente,
      'razonSocial': razonSocial,
      'fecha': fecha,
      'importes': importes,
      'producto': producto,
    });
  }

  Future<void> eliminarImporteCliente(int idConsumo) async {
    await api.postJson('Clientes/eliminar.php', {
      'idConsumo': idConsumo,
    });
  }
}
