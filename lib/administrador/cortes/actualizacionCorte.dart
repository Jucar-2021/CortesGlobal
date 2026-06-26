import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tarjetasCajero/baucherCajero.dart';
import '../../clientes/listadoClientes.dart';
import '../../api/consumoPHP.dart';
import '../../api/documentos/registroDoc_api.dart';
import '../../api/cortes/manejoCortes_api.dart';

class ActualizarCorte extends StatefulWidget {
  const ActualizarCorte({
    super.key,
    required this.idCorte,
    required this.fecha,
    required this.user,
    required this.idUsuario,
    required this.turno,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    this.ventaInicial,
    this.gastosInicial,
    this.cajeroInicial,
    this.buzonInicial,
    this.clientesInicial,
  });

  final int idCorte;
  final String fecha;
  final String user;
  final int idUsuario;
  final String turno;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  final String? ventaInicial;
  final String? gastosInicial;
  final double? cajeroInicial;
  final double? buzonInicial;
  final double? clientesInicial;

  @override
  State<ActualizarCorte> createState() => _ActualizarCorteState();
}

class _ActualizarCorteState extends State<ActualizarCorte> {
  late int idCorte;
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

  double _totalCobrosTPV = 0;
  double _totalClientes = 0;
  double _totalCajero = 0;
  double _totalBuzon = 0;
  double totalFinal = 0;

  bool _guardando = false;

  SharedPreferences? _prefs;
  bool _prefsReady = false;

  // ======== BANCOS / TPV ========
  final ApiService _apiService = ApiService();
  late final DocuementosApi _docuementosApi;
  List<Map<String, dynamic>> _bancos = [];
  late Future<List<Map<String, dynamic>>> _futureBancos;

  String get _saldosKey => 'saldos_clientes_act_${idUsuario}_${fecha}_$turno';

  // ======== FORMATO DINERO ========
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  String _fmt(double valor) => _currencyFormat.format(valor);

  String _k(String key) => '${key}_act_${idUsuario}_${fecha}_$turno';

  @override
  void initState() {
    super.initState();

    idCorte = widget.idCorte;
    fecha = widget.fecha;
    user = widget.user;
    idUsuario = widget.idUsuario;
    turno = widget.turno;
    nombre = widget.nombre;
    apellidoPaterno = widget.apellidoPaterno;
    apellidoMaterno = widget.apellidoMaterno;

    _ventaController = TextEditingController();

    _docuementosApi = DocuementosApi(_apiService);
    _futureBancos = _initBancosPage();

    _initPrefsAndLoad();
  }

  Future<void> _initPrefsAndLoad() async {
    _prefs = await SharedPreferences.getInstance();

    _ventaController.text =
        _prefs!.getString(_k('ventaDia')) ?? widget.ventaInicial ?? '';
    _gastosController.text =
        _prefs!.getString(_k('gastos')) ?? widget.gastosInicial ?? '';

    _totalCobrosTPV = _prefs!.getDouble(_k('totalCobrosTPV')) ?? 0.0;
    _totalBuzon =
        _prefs!.getDouble(_k('totalBuzon')) ?? widget.buzonInicial ?? 0.0;
    _totalCajero =
        _prefs!.getDouble(_k('totalCajero')) ?? widget.cajeroInicial ?? 0.0;
    _totalClientes =
        _prefs!.getDouble(_k('totalClientes')) ?? widget.clientesInicial ?? 0.0;

    _prefsReady = true;
    _recalcularTotal();
    if (mounted) setState(() {});
  }

  // ======== INIT BANCOS ========
  Future<List<Map<String, dynamic>>> _initBancosPage() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _prefsReady = true;
    }
    await _fetchBancos();
    await _aplicarSaldosGuardados();
    await _recargarTotalesTPV();
    return _bancos;
  }

  Future<void> _fetchBancos() async {
    try {
      final bancos = await _docuementosApi.getBancos();
      _bancos = List<Map<String, dynamic>>.from(bancos);
    } catch (e) {
      debugPrint('Error al obtener bancos: $e');
    }
  }

  Future<void> _aplicarSaldosGuardados() async {
    if (_prefs == null) return;
    final jsonString = _prefs!.getString(_saldosKey);
    if (jsonString == null || jsonString.isEmpty) return;
    final Map<String, dynamic> saldosGuardados = jsonDecode(jsonString);
    for (final banco in _bancos) {
      final id = (banco['idBanco'] as num?)?.toInt() ?? 0;
      if (saldosGuardados.containsKey(id.toString())) {
        banco['saldoTotal'] = (saldosGuardados[id.toString()] as num)
            .toDouble();
      }
    }
  }

  Future<void> _guardarSaldosLocales() async {
    if (_prefs == null) return;
    final Map<String, double> saldos = {};
    for (final banco in _bancos) {
      final id = (banco['idBanco'] as num?)?.toInt() ?? 0;
      final saldo = banco['saldoTotal'];
      final valor = saldo is num
          ? saldo.toDouble()
          : double.tryParse(saldo.toString()) ?? 0.0;
      saldos[id.toString()] = valor;
    }
    await _prefs!.setString(_saldosKey, jsonEncode(saldos));
  }

  Future<void> _recargarTotalesTPV() async {
    if (_bancos.isEmpty) return;
    try {
      final resultados = await Future.wait(
        _bancos.map((banco) async {
          final idBanco = (banco['idBanco'] as num?)?.toInt() ?? 0;
          final total = await _docuementosApi.obtenerTotalDatos(
            idBanco: idBanco,
            idUsuario: idUsuario,
            fecha: fecha,
            turno: turno,
          );
          return MapEntry(idBanco, total);
        }),
      );

      if (!mounted) return;

      setState(() {
        for (final entry in resultados) {
          final i = _bancos.indexWhere(
            (c) => (c['idBanco'] as num?)?.toInt() == entry.key,
          );
          if (i != -1) _bancos[i]['saldoTotal'] = entry.value;
        }
        _totalCobrosTPV = _calcularTotalGeneral();
      });

      _recalcularTotal();
      await _saveDouble('totalCobrosTPV', _totalCobrosTPV);
      await _guardarSaldosLocales();
    } catch (e) {
      debugPrint('Error recargando totales TPV: $e');
    }
  }

  Future<void> _abrirCapturaTPV({
    required int idBanco,
    required String banco,
  }) async {
    await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDocumentosPage(
          idBanco: idBanco,
          banco: banco,
          idUsuario: idUsuario,
          fecha: fecha,
          turno: turno,
        ),
      ),
    );
    if (!mounted) return;
    await _recargarTotalesTPV();
  }

  double _calcularTotalGeneral() {
    double total = 0;
    for (final banco in _bancos) {
      final saldo = banco['saldoTotal'];
      final valor = saldo is num
          ? saldo.toDouble()
          : double.tryParse(saldo.toString()) ?? 0.0;
      total += valor;
    }
    return total;
  }

  @override
  void dispose() {
    _ventaController.dispose();
    _gastosController.dispose();
    _billetesController.dispose();
    _monedasController.dispose();
    super.dispose();
  }

  void _recalcularTotal() {
    final venta = double.tryParse(_ventaController.text) ?? 0;
    final gas = double.tryParse(_gastosController.text) ?? 0;
    final billetes = double.tryParse(_billetesController.text) ?? 0;
    final monedas = double.tryParse(_monedasController.text) ?? 0;

    setState(() {
      totalFinal =
          venta -
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
    await _prefs!.remove(_k('totalCobrosTPV'));
    await _prefs!.remove(_k('totalClientes'));
    await _prefs!.remove(_k('billetes'));
    await _prefs!.remove(_k('monedas'));
    await _prefs!.remove(_saldosKey);
  }

  Future<void> _editarCajero(String banco) async {
    final resultado = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDocumentosPage(
          fecha: fecha,
          idUsuario: widget.idUsuario,
          turno: turno,
          banco: banco,
        ),
      ),
    );
    if (resultado != null) {
      setState(() => _totalCajero = resultado);
      await _saveDouble('totalCajero', resultado);
      _recalcularTotal();
    }
  }

  Future<void> _editarBuzon(String banco) async {
    final resultado = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDocumentosPage(
          fecha: fecha,
          idUsuario: widget.idUsuario,
          turno: turno,
          banco: banco,
        ),
      ),
    );
    if (resultado != null) {
      setState(() => _totalBuzon = resultado);
      await _saveDouble('totalBuzon', resultado);
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
          soloActivos: false,
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
    final confirmacion = await _showConfirmacionDialog();
    if (!confirmacion) return;
    if (_guardando) return;

    final venta = double.tryParse(_ventaController.text) ?? 0;
    final gastos = double.tryParse(_gastosController.text) ?? 0;

    if (venta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La venta del día no puede ser cero.")),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    try {
      await _actualizarCorte(
        venta: venta,
        cobros_tpv: _totalCobrosTPV,
        clientes: _totalClientes,
        cajero: _totalCajero,
        buzon: _totalBuzon,
        gastos: gastos,
      );

      await _clearDraft();

      if (!mounted) return;
      setState(() => _guardando = false);
      _showCorteActualizadoDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar el corte: $e")),
      );
    }
  }

  Future<void> _actualizarCorte({
    required double venta,
    required double cobros_tpv,
    required double clientes,
    required double cajero,
    required double buzon,
    required double gastos,
  }) async {
    final api = ManejocortesApi(_apiService);
    await api.actualizarCorte(
      idCorte: idCorte,
      venta: venta,
      cobros_tpv: cobros_tpv,
      clientes: clientes,
      cajero: cajero,
      buzon: buzon,
      gastos: gastos,
    );
  }

  // ======== OVERLAY GUARDANDO ========
  Widget _overlayGuardando() {
    return Positioned.fill(
      child: Container(
        color: const Color.fromARGB(200, 82, 80, 80),
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
                Flexible(
                  child: Text(
                    'Actualizando corte de $user ...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCorteActualizadoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Corte actualizado"),
        content: const Text("El corte ha sido actualizado exitosamente."),
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

  Future<bool> _showConfirmacionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Confirmar actualización",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "¿Estás seguro de que deseas actualizar este corte?\n\nAsegúrate de que toda la información sea correcta.",
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Actualizar"),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              "Editar corte — $turno",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            Text(
              _formatoFecha(fecha),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      _buildListaBancos(),
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
                            : () => _editarCajero('Cajero'),
                      ),
                      const SizedBox(height: 10),
                      _buildResumenCard(
                        titulo: "Efectivo en oficina",
                        valor: _fmt(_totalBuzon),
                        icono: Icons.credit_card,
                        onTap: _guardando ? null : () => _editarBuzon('Buzon'),
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
                        "Actualizar Corte",
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

  Widget _buildListaBancos() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureBancos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _bancos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && _bancos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Error al cargar bancos: ${snapshot.error}'),
          );
        }
        final bancos = _bancos.isNotEmpty ? _bancos : (snapshot.data ?? []);
        if (bancos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No se encontraron bancos'),
          );
        }
        return Column(
          children: [
            ...bancos.map((banco) {
              final int idBanco = (banco['idBanco'] as num?)?.toInt() ?? 0;
              final String nombreBanco =
                  banco['nombreBanco']?.toString() ?? 'Sin nombre';
              final double saldo = (banco['saldoTotal'] is num)
                  ? (banco['saldoTotal'] as num).toDouble()
                  : double.tryParse(banco['saldoTotal']?.toString() ?? '0') ??
                        0.0;
              final bool esActivo =
                  (int.tryParse(banco['estado'].toString()) ?? 0) == 1;
              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.credit_card, color: Color(0xFF1565C0)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombreBanco,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: esActivo
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          esActivo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: esActivo
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _fmt(saldo),
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.edit_document,
                      color: Color(0xFF1565C0),
                    ),
                    onPressed: _guardando
                        ? null
                        : () => _abrirCapturaTPV(
                            idBanco: idBanco,
                            banco: nombreBanco,
                          ),
                  ),
                ),
              );
            }),
            Card(
              color: const Color(0xFFE3F2FD),
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total cobros TPV',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    Text(
                      _fmt(_totalCobrosTPV),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.25)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF1565C0)),
          onPressed: onTap,
        ),
      ),
    );
  }

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
