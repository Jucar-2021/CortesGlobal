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
    int? idBanco
  }) async {
    final res = await api.postJson('TarjetasCajero/obtener.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'banco': banco,
      'idBanco': idBanco,
    });

    final data = res['data'];
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
    int? idBanco,
  }) async {
    await api.postJson('TarjetasCajero/registrar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'importes': importes,
      'banco': banco,
      'idBanco': idBanco,
    });
  }

  // Actualizacion de datos
  Future<void> actualizarDatos({
    required int idUsuario,
    required String fecha,
    required List<double> importes,
    required String turno,
    required String banco,
    int? idBanco,
  }) async {
    await api.postJson('TarjetasCajero/actualizar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'turno': turno,
      'importes': importes,
      'banco': banco,
      'idBanco': idBanco,
    });
  }

  // Eliminacion de datos
  Future<void> eliminarDatos({required int id, String? banco}) async {
    print('Eliminando tarjeta TarjetasCajero con id: $id');
    print(' Banco: $banco');
    await api.postJson('TarjetasCajero/eliminar.php', {
      'id': id,
      'banco': banco,
    });
  }

  Future<double> obtenerTotalDatos({
    required int idBanco,
    required int idUsuario,
    required String fecha,
    required String turno,
  }) async {
    final rows = await obtenerDatos(
      idBanco: idBanco,
      idUsuario: idUsuario,
      fecha: fecha,
      turno: turno,
      banco: '',
    );

    double total = 0.0;

    for (final row in rows) {
      final importe = (row['importe'] as num?)?.toDouble() ?? 0.0;
      total += importe;
    }

    return total;
  }
}
