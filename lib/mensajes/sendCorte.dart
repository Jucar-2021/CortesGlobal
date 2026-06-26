import 'package:intl/intl.dart';
import '../api/notificaciones/telegramSend_api.dart';
import '../api/consumoPHP.dart';

class Notificaciones {
  final ApiService api = ApiService();

  late final TelegramApi send = TelegramApi(api);

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  String _fmt(double valor) => _currencyFormat.format(valor);

  Future<void> enviarCorte({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String turno,
    required String fecha,
    required double totalFinal,
    required double totalCobrosTPV,
    required double totalClientes,
    required double totalCajero,
    required double totalBuzon,
    required String ventaController,
    required String gastosController,
    required String billetesController,
    required String monedasController,
    required List<Map<String, dynamic>> bancos,
  }) async {
    try {
      final venta = double.tryParse(ventaController) ?? 0;
      final gastos = double.tryParse(gastosController) ?? 0;
      final billetes = double.tryParse(billetesController) ?? 0;
      final monedas = double.tryParse(monedasController) ?? 0;

      final totalEntregado = totalFinal + billetes + monedas;
      final totalEfectivo =
          venta - totalCobrosTPV - totalClientes - gastos;

      final bancosConSaldo = bancos.where((b) {
        final s = b['saldoTotal'];
        final v = s is num
            ? s.toDouble()
            : double.tryParse(s?.toString() ?? '0') ?? 0.0;
        return v > 0;
      }).toList();

      final detalleTPV = bancosConSaldo.isNotEmpty
          ? bancosConSaldo.map((b) {
              final nombreBanco = b['nombreBanco']?.toString() ?? 'Banco';
              final s = b['saldoTotal'];
              final saldo = s is num
                  ? s.toDouble()
                  : double.tryParse(s?.toString() ?? '0') ?? 0.0;
              return '   • $nombreBanco: ${_fmt(saldo)}';
            }).join('\n')
          : '   (sin capturas)';

      final mensaje = '''
<b>⛽ CORTE DESPACHADOR</b>
👤 <b>$nombre $apellidoPaterno $apellidoMaterno</b>

━━━━━━━━━━━━━━━━━━
⏰ <b>Turno:</b> <code>$turno</code>
📅 <b>Fecha:</b> <b>$fecha</b>
━━━━━━━━━━━━━━━━━━
💰 <b>Venta del día:</b> ${_fmt(venta)}

🏦 <b>Tarjetas Bancarias:</b>
$detalleTPV
   <b>Total TPV: ${_fmt(totalCobrosTPV)}</b>

👥 <b>Total clientes:</b> ${_fmt(totalClientes)}

━━━━━━━━━━━━━━━━━━
🏧 <b>Depósitos Cajero:</b> ${_fmt(totalCajero)}
📥 <b>Efectivo oficina:</b> ${_fmt(totalBuzon)}
🧾 <b>Gastos:</b> ${_fmt(gastos)}

━━━━━━━━━━━━━━━━━━
🔴 <b>TOTAL ENTREGADO:</b>
🟰 <b>${_fmt(totalEntregado)}</b>

💵 <b>Billetes:</b> ${_fmt(billetes)}
💰 <b>Monedas:</b> ${_fmt(monedas)}
━━━━━━━━━━━━━━━━━━
🟢 <b>TOTAL EFECTIVO:</b>
💰 <b>${_fmt(totalEfectivo)}</b>
''';

      await send.sendMessage(mensaje);
    } catch (e) {
      throw Exception('Error enviando mensaje a Telegram: $e');
    }
  }
}