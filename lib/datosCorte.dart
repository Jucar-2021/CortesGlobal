import 'package:cortes_despachador/tarjetasCajero/listadoTPV.dart';

import 'tarjetasCajero/baucherCajero.dart';
import 'package:flutter/material.dart';
import 'clientes/listadoClientes.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/cortes/guardarCorte_api.dart';
import 'api/telegramSend_api.dart';
import 'api/consumoPHP.dart';

class DatoCorte extends StatefulWidget {
  const DatoCorte({
    super.key,
    required this.fecha,
    required this.user,
    required this.idUsuario,
    required this.tipoZonaCorte,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  final String fecha;
  final String user;
  final int idUsuario;
  final String tipoZonaCorte;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  @override
  State<DatoCorte> createState() => _DatoCorteState();
}

class _DatoCorteState extends State<DatoCorte> {
  late String fecha;
  late String user;
  late int idUsuario;
  late String turno;
  late String nombre;
  late String apellidoPaterno;
  late String apellidoMaterno;

  late TextEditingController _ventaController;
  final TextEditingController _gastosController = TextEditingController();
  final TextEditingController _billetesController = TextEditingController();
  final TextEditingController _monedasController = TextEditingController();

  final TelegramApi _corteTelegram = TelegramApi(ApiService());

  double _totalCobrosTPV = 0;
  double _totalClientes = 0;
  double _totalCajero = 0;
  double _totalBuzon =0;
  double totalFinal = 0;

  bool _guardando = false;

  SharedPreferences? _prefs;
  bool _prefsReady = false;

  // ======== FORMATO DINERO ========
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  String _fmt(double valor) => _currencyFormat.format(valor);

  // Key con contexto (evita mezclar datos entre usuarios/fechas/producto)
  String _k(String key) => '${key}_${idUsuario}_${fecha}_$turno';

  @override
  void initState() {
    super.initState();

    fecha = widget.fecha;
    user = widget.user;
    idUsuario = widget.idUsuario;
    turno = widget.tipoZonaCorte;
    nombre = widget.nombre;
    apellidoPaterno = widget.apellidoPaterno;
    apellidoMaterno = widget.apellidoMaterno;

    _ventaController = TextEditingController();

    _initPrefsAndLoad();
  }

  Future<void> _initPrefsAndLoad() async {
    _prefs = await SharedPreferences.getInstance();

    // Cargar valores texto
    _ventaController.text = _prefs!.getString(_k('ventaDia')) ?? '';
    _gastosController.text = _prefs!.getString(_k('gastos')) ?? '';

    // Cargar totales
    _totalCobrosTPV = _prefs!.getDouble(_k('totalCobrosTPV')) ?? 0.0;
    _totalBuzon = _prefs!.getDouble(_k('totalBuzon')) ?? 0.0;
    _totalCajero = _prefs!.getDouble(_k('totalCajero')) ?? 0.0;
    _totalClientes = _prefs!.getDouble(_k('totalClientes')) ?? 0.0;

    _prefsReady = true;

    _recalcularTotal();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ventaController.dispose();
    _gastosController.dispose();
    _billetesController.dispose();
    _monedasController.dispose();
    super.dispose();
  }

  // ======== RECALCULAR TOTAL ========
  void _recalcularTotal() {
    final venta = double.tryParse(_ventaController.text) ?? 0;
    final gas = double.tryParse(_gastosController.text) ?? 0;
    final billetes = double.tryParse(_billetesController.text) ?? 0;
    final monedas = double.tryParse(_monedasController.text) ?? 0;

    setState(() {
      totalFinal = venta -
          _totalCobrosTPV -
          _totalClientes -
          _totalCajero -
          _totalBuzon -
          gas -
          billetes -
          monedas;
    });
  }

  Future<void> _saveString(String key, String value) async {
    if (!_prefsReady || _prefs == null) return;
    await _prefs!.setString(_k(key), value);
  }

  Future<void> _saveDouble(String key, double value) async {
    if (!_prefsReady || _prefs == null) return;
    await _prefs!.setDouble(_k(key), value);
  }

  Future<void> _clearDraft() async {
    if (!_prefsReady || _prefs == null) return;

    await _prefs!.remove(_k('ventaDia'));
    await _prefs!.remove(_k('totalCajero'));
    await _prefs!.remove(_k('totalBuzon'));
    await _prefs!.remove(_k('gastos'));
    await _prefs!.remove(_k('ajustedep'));
    await _prefs!.remove(_k('totalCobrosTPV'));
    await _prefs!.remove(_k('totalClientes'));
    await _prefs!.remove(_k('billetes'));
    await _prefs!.remove(_k('monedas'));
  }

  // Metodo genérico para navegar hacia cualquier banco registrado
  Future<void> _editarDocumentos(String banco) async {
    final resultado = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDocumentosPage(
            fecha: fecha,
            idUsuario: widget.idUsuario,
            turno: turno,
            banco: banco),
      ),
    );

    if (resultado != null) {
      setState(() => _totalCobrosTPV = resultado);
      await _saveDouble('totalCobrosTPV', resultado);
      _recalcularTotal();
    }
  }

  Future<void> _editarTPV() async {
    final resultado = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => ListaBancos(
          fecha: fecha,
          user: user,
          idUsuario: widget.idUsuario,
          turno: turno,
        ),
      ),
    );

    if (resultado != null) {
      setState(() => _totalClientes = resultado);
      await _saveDouble('totalClientes', resultado);
      _recalcularTotal();
    }
  }

  Future<void> _editarClientes() async {
    final resultado = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => Listadoclientes(
          fecha: fecha,
          user: user,
          idUsuario: widget.idUsuario,
          turno: turno,
        ),
      ),
    );

    if (resultado != null) {
      setState(() => _totalClientes = resultado);
      await _saveDouble('totalClientes', resultado);
      _recalcularTotal();
    }
  }

  // ======== BOTÓN GUARDAR ========
  Future<void> _onGuardarPressed() async {
    final confirmacion = await _showConfirmacionGuardarDialog();
    if (!confirmacion) return;

    if (_guardando) return;

    final venta = double.tryParse(_ventaController.text) ?? 0;
    final billetes = double.tryParse(_billetesController.text) ?? 0;
    final monedas = double.tryParse(_monedasController.text) ?? 0;
    final gastos = double.tryParse(_gastosController.text) ?? 0;
    final cajero = _totalCajero;

    final cobros_TPV = _totalCobrosTPV;
    final buzon = _totalBuzon;
    final clientes = _totalClientes;

    final total = totalFinal + billetes + monedas;

    if (venta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La venta del día no puede ser cero.")),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      await _guardarCorte(
        fecha,
        idUsuario,
        user,
        turno,
        venta,
        cobros_TPV,
        cajero,
        buzon,
        gastos,
        clientes,
        total
      );

      await _enviarCorteTelegram();

      // Limpia borrador local cuando guardó exitosamente
      await _clearDraft();

      if (!mounted) return;
      setState(() => _guardando = false);

      _showCorteGuardadoDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar el corte: $e")),
      );
    }
  }

  // ======== OVERLAY GUARDANDO ========
  Widget _overlayGuardando() {
    return Positioned.fill(
      child: Container(
        color: const Color.fromARGB(255, 82, 80, 80),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 14),
                Text(
                  'Guardando tu corte $user ...',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======== GUARDAR CORTE EN BD ========
  Future<void> _guardarCorte(
    String fecha,
    int idUsuario,
    String usuario,
    String turno,
    double venta,
    double cobrosTPV,
    double cajero,
    double buzon,
    double gastos,
    double clientes,
    double total,
  ) async {
    final corteApi = CorteApi(ApiService());

    await corteApi.guardarCorte(
      fecha: fecha,
      idUsuario: idUsuario,
      usuario: "$nombre $apellidoPaterno $apellidoMaterno",
      turno: turno,
      venta: venta,
      cobrosTPV: cobrosTPV,
      cajero: cajero,
      buzon: buzon,
      gastos: gastos,
      clientes: clientes,
      efectivoEntregado: total,
    );
  }

  // ======== ENVIAR A TELEGRAM ========
  Future<void> _enviarCorteTelegram() async {
    final mensaje = '''
<b>⛽ CORTE DESPACHADOR</b>
👤 <b>$nombre $apellidoPaterno $apellidoMaterno</b>

━━━━━━━━━━━━━━━━━━
⛽ <b>Producto:</b> <code>$turno</code>
📅 <b>Fecha:</b> <b>$fecha</b>
━━━━━━━━━━━━━━━━━━
💰 <b>Venta del día:</b> ${_fmt(double.tryParse(_ventaController.text) ?? 0)}

♨🏦 <b>Tarjetas Bancarias:</b> ${_fmt(_totalCobrosTPV)}


👥 <b>Total clientes:</b> ${_fmt(_totalClientes)}

━━━━━━━━━━━━━━━━━━
🏧 <b>Depósitos Cajero:</b> ${_fmt((_totalCajero))}
📥 <b>Efectivo oficina:</b> ${_fmt(_totalBuzon)}
🧾 <b>Gastos:</b> ${_fmt(double.tryParse(_gastosController.text) ?? 0)}

━━━━━━━━━━━━━━━━━━
🔴 <b>TOTAL ENTREGADO:</b>
🟰 <b>${_fmt((totalFinal) + (double.tryParse(_billetesController.text) ?? 0) + (double.tryParse(_monedasController.text) ?? 0))}</b>

💵 <b>Billetes: ${_fmt(double.tryParse(_billetesController.text) ?? 0)}</b>
💰 <b>Monedas: ${_fmt(double.tryParse(_monedasController.text) ?? 0)}</b>
━━━━━━━━━━━━━━━━━━
🟢 <b>TOTAL EFECTIVO:</b>
💰 <b>${_fmt((double.tryParse(_ventaController.text) ?? 0) - _totalCobrosTPV - _totalClientes - (double.tryParse(_gastosController.text) ?? 0))}</b>
''';

    await _corteTelegram.sendMessage(mensaje);
  }

  //Show de confirmacion de corte guardado exitosamente
  void _showCorteGuardadoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Corte guardado y enviado a Telegram"),
        content: const Text("Tu corte ha sido guardado exitosamente."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  //show para confirmacion final para guardar corte
  Future<bool> _showConfirmacionGuardarDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirmar guardado",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
                "¿Estás seguro de que deseas guardar este corte?\n\nAsegúrate de que toda la información sea correcta.",
                style: TextStyle(fontWeight: FontWeight.w400)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Guardar"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$nombre $apellidoPaterno $apellidoMaterno",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              "Corte de la $turno, fecha:",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              _formatoFecha(fecha),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle("Venta del día"),
                      _buildCustomField(
                        controller: _ventaController,
                        enabled: !_guardando,
                        label: "Venta del día",
                        onChanged: (value) async {
                          await _saveString('ventaDia', value);
                          _recalcularTotal();
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle("Tarjetas"),
                      _buildResumenCard(
                        titulo: "Total cobros TPV",
                        valor: _fmt(_totalCobrosTPV),
                        icono: Icons.people_alt_outlined,
                        onTap: _guardando ? null : _editarTPV,
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle("Clientes"),
                      _buildResumenCard(
                        titulo: "Total clientes",
                        valor: _fmt(_totalClientes),
                        icono: Icons.people_alt_outlined,
                        onTap: _guardando ? null : _editarClientes,
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle("Otros movimientos"),
                      _buildResumenCard(
                        titulo: "Depósitos en cajero",
                        valor: _fmt(_totalCajero),
                        icono: Icons.account_balance,
                        onTap: _guardando
                            ? null
                            : () => _editarDocumentos('Cajero'),
                      ),
                      const SizedBox(height: 10),
                      _buildResumenCard(
                        titulo: "Efectivo en oficina",
                        valor: _fmt(_totalBuzon),
                        icono: Icons.credit_card,
                        onTap: _guardando
                            ? null
                            : () => _editarDocumentos('Buzon'),
                      ),
                      const SizedBox(height: 10),
                      _buildCustomField(
                        controller: _gastosController,
                        enabled: !_guardando,
                        label: "Gastos",
                        onChanged: (value) async {
                          await _saveString('gastos', value);
                          _recalcularTotal();
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle("Detalle de efectivo entregado"),
                      _buildCustomField(
                        controller: _billetesController,
                        enabled: !_guardando,
                        label: "Total Billetes",
                        onChanged: (value) async {
                          await _saveString('billetes', value);
                          _recalcularTotal();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCustomField(
                        controller: _monedasController,
                        enabled: !_guardando,
                        label: "Total Monedas",
                        onChanged: (value) async {
                          await _saveString('monedas', value);
                          _recalcularTotal();
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: totalFinal < 0
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: totalFinal < 0
                                ? const Color(0xFF43A047).withOpacity(0.30)
                                : const Color(0xFFFB8C00).withOpacity(0.30),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Diferencia a entregar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalFinal < 0
                                  ? "${_fmt(totalFinal)} (SOBRANTE)"
                                  : _fmt(totalFinal),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: totalFinal < 0
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFEF6C00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    MediaQuery.of(context).viewPadding.bottom > 0 ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _onGuardarPressed,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        "Guardar Corte",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_guardando) _overlayGuardando(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1),
        ),
      ),
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.blueGrey.withOpacity(0.25),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: Color(0xFF1565C0),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildResumenCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          child: Icon(icono, color: const Color(0xFF1565C0)),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF1565C0)),
          onPressed: onTap,
        ),
      ),
    );
  }

  //formato de fecha DD/MM/YYYY
  String _formatoFecha(String fecha) {
    try {
      final partes = fecha.split('/');
      if (partes.length != 3) return fecha;

      final an = partes[0];
      final mes = partes[1];
      final dia = partes[2];

      return '$dia/$mes/$an';
    } catch (e) {
      return fecha;
    }
  }
}
