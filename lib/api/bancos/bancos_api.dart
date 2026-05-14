import '../consumoPHP.dart';

class BancosApi {
  final ApiService api;

  BancosApi(this.api);

  Future<List<Map<String, dynamic>>> getBancos() async {
    final res = await api.postJson('TarjetasCajero/listar.php', {});
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  // registrar banco
  Future<void> registrarBanco({required String nombreBanco}) async {
    await api.postJson('Bancos/registrar.php', {'nombreBanco': nombreBanco});
  }

  // actualizar banco
  Future<void> actualizarBanco({
    required int idBanco,
    required String nombreBanco,
  }) async {
    await api.postJson('Bancos/modificar.php', {
      'idBanco': idBanco,
      'nombreBanco': nombreBanco,
    });
  }

  // eliminar banco
  Future<void> eliminarBanco({required int idBanco}) async {
    await api.postJson('Bancos/eliminar.php', {'idBanco': idBanco});
  }

  // estado de banco
  Future<void> cambiarEstadoBanco({
    required int idBanco,
    required String estado,
  }) async {
    await api.postJson('Bancos/cambiar_estado.php', {
      'idBanco': idBanco,
      'estado': estado,
    });
  }


}
