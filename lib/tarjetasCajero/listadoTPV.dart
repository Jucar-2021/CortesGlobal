import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/documentos/registroDoc_api.dart';
import '../api/consumoPHP.dart';
import 'baucherCajero.dart';

class ListaBancos extends StatefulWidget {
  const ListaBancos({
    super.key,
    required this.idUsuario,
    required this.fecha,
    required this.user,
    required this.turno,
  });

  final int idUsuario;
  final String fecha;
  final String user;
  final String turno;

  @override
  State<ListaBancos> createState() => _ListaBancosState();
}

class _ListaBancosState extends State<ListaBancos> {
  final ApiService apiService = ApiService();
  late final DocuementosApi docuementosApi;
  late Future<List<Map<String, dynamic>>> _futureBancos;

  List<Map<String, dynamic>> _bancos = [];

  SharedPreferences? _prefs;
  bool _prefsReady = false;

  String get _saldosKey =>
      'saldos_clientes_${widget.idUsuario}_${widget.fecha}_${widget.turno}';

  @override
  void initState() {
    super.initState();
    docuementosApi = DocuementosApi(apiService);

    _futureBancos = _initPage();
  }

  Future<List<Map<String, dynamic>>> _initPage() async {
    _prefs = await SharedPreferences.getInstance();
    _prefsReady = true;

    final bancos = await fetchBancos();
    await _aplicarSaldosGuardados();
    await _recargarTotalesTPV();

    return bancos;
  }

  Future<List<Map<String, dynamic>>> fetchBancos() async {
    try {
      final bancos = await docuementosApi.getBancos();

      // SOLO BANCOS ACTIVOS
      final bancosActivos = bancos.where((banco) {
        final estado =
            int.tryParse(banco['estado'].toString()) ?? 0;

        return estado == 1;
      }).toList();

      _bancos = List<Map<String, dynamic>>.from(bancosActivos);

      return _bancos;

    } catch (e) {
      debugPrint('Error al obtener bancos: $e');
      return [];
    }
  }

  Future<void> _aplicarSaldosGuardados() async {
    if (!_prefsReady || _prefs == null) return;

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
    if (!_prefsReady || _prefs == null) return;

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

          final total = await docuementosApi.obtenerTotalDatos(
            idBanco: idBanco,
            idUsuario: widget.idUsuario,
            fecha: widget.fecha,
            turno: widget.turno,
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

          if (i != -1) {
            _bancos[i]['saldoTotal'] = entry.value;
          }
        }
      });

      await _guardarSaldosLocales();
    } catch (e) {
      debugPrint('Error recargando totales de clientes: $e');
    }
  }

  Future<void> _abrirCapturaTPV({
    required int idBanco,
    required String banco,
  }) async {
    final total = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDocumentosPage(
          idBanco: idBanco,
          banco: banco,
          idUsuario: widget.idUsuario,
          fecha: widget.fecha,
          turno: widget.turno,
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  String _fmt(double valor) {
    return _currencyFormat.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Bancos'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureBancos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
              _bancos.isEmpty) {
            return const Center(child: Text('No se encontraron bancos'));
          }

          final bancos = _bancos.isNotEmpty ? _bancos : snapshot.data!;
          final totalGeneral = _calcularTotalGeneral();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bancos.length,
                  itemBuilder: (context, index) {
                    final banco = bancos[index];

                    final int idBanco =
                        (banco['idBanco'] as num?)?.toInt() ?? 0;
                    final String nombreBanco =
                        banco['nombreBanco']?.toString() ?? 'Sin nombre';

                    final double saldo = (banco['saldoTotal'] is num)
                        ? (banco['saldoTotal'] as num).toDouble()
                        : double.tryParse(
                                banco['saldoTotal']?.toString() ?? '0',
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
                              nombreBanco,
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
                                  await _abrirCapturaTPV(
                                    idBanco: idBanco,
                                    banco: nombreBanco,
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
