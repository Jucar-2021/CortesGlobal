import '../consumoPHP.dart';

class ClienteAdminApi {
  final ApiService api;

  ClienteAdminApi(this.api);

  Future<List<Map<String, dynamic>>> getClientes() async {
    final res = await api.postJson('Clientes/listar.php', {});
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future<void> registrarCliente({required String razonSocial}) async {
    await api.postJson('Clientes/manejo/registrar.php', {
      'razonSocial': razonSocial,
    });
  }

  Future<void> actualizarCliente({
    required int IdCliente,
    required String razonSocial,
  }) async {
    await api.postJson('Clientes/manejo/actualizar.php', {
      'IdCliente': IdCliente,
      'razonSocial': razonSocial,
    });
  }

  Future<void> cambiarEstadoCliente({
    required int IdCliente,
    required int estado,
  }) async {
    await api.postJson('Clientes/manejo/estado.php', {
      'IdCliente': IdCliente,
      'estado': estado,
    });
  }

  Future<void> eliminarCliente({required int IdCliente}) async {
    await api.postJson('Bancos/manejo/eliminar.php', {'IdCliente': IdCliente});
  }
}
