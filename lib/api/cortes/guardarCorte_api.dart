import '../consumoPHP.dart';

class CorteApi {
  final ApiService api;
  CorteApi(this.api);

  Future<void> guardarCorte({
    required int idUsuario,
    required String fecha,
    required String usuario,
    required String turno,
    required double venta,
    required double cobros_tpv,
    required double clientes,
    required double cajero,
    required double buzon,
    required double gastos,
  }) async {
    await api.postJson('Cortes/registrar.php', {
      'idUsuario': idUsuario,
      'fecha': fecha,
      'usuario': usuario,
      'turno': turno,
      'venta': venta,
      'cobros_tpv': cobros_tpv,
      'clientes': clientes,
      'cajero': cajero,
      'buzon': buzon,
      'gastos': gastos,
    });
  }
}
