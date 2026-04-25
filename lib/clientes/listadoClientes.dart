import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client/clientes_api.dart';
import '../api/consumoPHP.dart';
import 'clientes.dart';

class Listadoclientes extends StatefulWidget {
  const Listadoclientes({
    super.key,
    required this.idUsuario,
    required this.fecha,
    required this.user,
    required this.producto,
  });

  final int idUsuario;
  final String fecha;
  final String user;
  final String producto;

  @override
  State<Listadoclientes> createState() => _ListadoclientesState();
}

class _ListadoclientesState extends State<Listadoclientes> {
  final ApiService apiService = ApiService();
  late final ClientesApi clientesApi;
  late Future<List<Map<String, dynamic>>> _futureClientes;

  List<Map<String, dynamic>> _clientes = [];

  SharedPreferences? _prefs;
  bool _prefsReady = false;

  String get _saldosKey =>
      'saldos_clientes_${widget.idUsuario}_${widget.fecha}_${widget.producto}';

  @override
  void initState() {
    super.initState();
    clientesApi = ClientesApi(apiService);

    _futureClientes = _initPage();
  }

  Future<List<Map<String, dynamic>>> _initPage() async {
    _prefs = await SharedPreferences.getInstance();
    _prefsReady = true;

    final clientes = await fetchClientes();
    await _aplicarSaldosGuardados();

    return clientes;
  }

  Future<List<Map<String, dynamic>>> fetchClientes() async {
    try {
      final clientes = await clientesApi.getClientes();

      _clientes = List<Map<String, dynamic>>.from(clientes);
      return _clientes;
    } catch (e) {
      debugPrint('Error al obtener clientes: $e');
      return [];
    }
  }

  Future<void> _aplicarSaldosGuardados() async {
    if (!_prefsReady || _prefs == null) return;

    final jsonString = _prefs!.getString(_saldosKey);
    if (jsonString == null || jsonString.isEmpty) return;

    final Map<String, dynamic> saldosGuardados = jsonDecode(jsonString);

    for (final cliente in _clientes) {
      final id = (cliente['IdCliente'] as num?)?.toInt() ?? 0;

      if (saldosGuardados.containsKey(id.toString())) {
        cliente['saldoTotal'] =
            (saldosGuardados[id.toString()] as num).toDouble();
      }
    }
  }

  Future<void> _guardarSaldosLocales() async {
    if (!_prefsReady || _prefs == null) return;

    final Map<String, double> saldos = {};

    for (final cliente in _clientes) {
      final id = (cliente['IdCliente'] as num?)?.toInt() ?? 0;
      final saldo = cliente['saldoTotal'];

      final valor = saldo is num
          ? saldo.toDouble()
          : double.tryParse(saldo.toString()) ?? 0.0;

      saldos[id.toString()] = valor;
    }

    await _prefs!.setString(_saldosKey, jsonEncode(saldos));
  }

  Future<void> clearDraft() async {
    if (!_prefsReady || _prefs == null) return;

    await _prefs!.remove(_saldosKey);

    if (!mounted) return;
    setState(() {
      for (final cliente in _clientes) {
        cliente['saldoTotal'] = 0.0;
      }
    });
  }

  Future<void> _abrirCapturaCliente({
    required int idCliente,
    required String razonSocial,
  }) async {
    final total = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientesCapturaPage(
          idCliente: idCliente,
          razonSocial: razonSocial,
          idUsuario: widget.idUsuario,
          fecha: widget.fecha,
          producto: widget.producto,
        ),
      ),
    );

    if (total != null && mounted) {
      setState(() {
        final i = _clientes.indexWhere(
          (c) => (c['IdCliente'] as num?)?.toInt() == idCliente,
        );

        if (i != -1) {
          _clientes[i]['saldoTotal'] = total;
        }
      });

      await _guardarSaldosLocales();
    }
  }

  double _calcularTotalGeneral() {
    double total = 0;

    for (final cliente in _clientes) {
      final saldo = cliente['saldoTotal'];
      final valor = saldo is num
          ? saldo.toDouble()
          : double.tryParse(saldo.toString()) ?? 0.0;

      total += valor;
    }

    return total;
  }

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  String _fmt(double valor) {
    return _currencyFormat.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Clientes'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureClientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
              _clientes.isEmpty) {
            return const Center(
              child: Text('No se encontraron clientes'),
            );
          }

          final clientes = _clientes.isNotEmpty ? _clientes : snapshot.data!;
          final totalGeneral = _calcularTotalGeneral();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];

                    final int idCliente =
                        (cliente['IdCliente'] as num?)?.toInt() ?? 0;
                    final String razonSocial =
                        cliente['razonSocial']?.toString() ?? 'Sin nombre';

                    final double saldo = (cliente['saldoTotal'] is num)
                        ? (cliente['saldoTotal'] as num).toDouble()
                        : double.tryParse(
                              cliente['saldoTotal']?.toString() ?? '0',
                            ) ??
                            0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              razonSocial,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saldo total: ${_fmt(saldo)}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _abrirCapturaCliente(
                                    idCliente: idCliente,
                                    razonSocial: razonSocial,
                                  );
                                },
                                icon: const Icon(Icons.edit_document),
                                label: const Text('Capturar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    MediaQuery.of(context).viewPadding.bottom > 0 ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 89, 138, 224),
                    border: const Border(
                      top: BorderSide(color: Colors.black12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL GENERAL: ${_fmt(totalGeneral)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, totalGeneral);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(
                            'Regresar',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
