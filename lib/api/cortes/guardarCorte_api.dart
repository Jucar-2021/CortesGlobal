import '../consumoPHP.dart';

class CorteApi {
  final ApiService api;
  CorteApi(this.api);

  Future<void> guardarCorte(
      {required String fecha,
      required int idUsuario,
      required String usuario,
      required String turno,
      required double venta,
      required double cobrosTPV,
      required double cajero,
      required double buzon,
      required double gastos,
      required double clientes,
      required double efectivoEntregado}) async {
    await api.postJson('Cortes/registrar.php', {
      'fecha': fecha,
      'idUsuario': idUsuario,
      'usuario': usuario,
      'venta': venta,
      'cobros_tpv': cobrosTPV,
      'cajero': cajero,
      'buzon': buzon,
      'gastos': gastos,
      'clientes': clientes,
      'turno': turno,
      'efectivoEntregado': efectivoEntregado,
    });
  }
}
