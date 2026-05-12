import '../api/documentos/registroRepo_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/consumoPHP.dart';

class IngresoReportes extends StatefulWidget {
  const IngresoReportes({super.key, required this.fecha});

  final String fecha;

  @override
  State<IngresoReportes> createState() => _IngresoReportesState();
}

class _IngresoReportesState extends State<IngresoReportes> {
  final ApiService apiService = ApiService();
  late final RegistroRepoApi reportesApi = RegistroRepoApi(apiService);

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  bool _cargando = true;

  final List<String> _bancos = ['Santander', 'Mifel', 'Monedero'];

  Map<String, double> _totales = {
    'Santander': 0,
    'Mifel': 0,
    'Monedero': 0,
  };

  @override
  void initState() {
    super.initState();
    _cargarTotales();
  }

  String _fmt(double valor) => _currencyFormat.format(valor);

  double _parseToDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _cargarTotales() async {
    try {
      setState(() => _cargando = true);

      final data =
          await reportesApi.obtenerTotales(fecha: widget.fecha, banco: '');

      final Map<String, double> nuevosTotales = {
        'Santander': 0,
        'Mifel': 0,
        'Monedero': 0,
      };

      for (final item in data) {
        final banco = item['banco'].toString();
        final total = _parseToDouble(item['total']);
        if (nuevosTotales.containsKey(banco)) {
          nuevosTotales[banco] = total;
        }
      }

      setState(() {
        _totales = nuevosTotales;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar totales: $e')),
      );
    }
  }

  Future<void> _abrirIngresoReportes(String banco) async {
    final actualizado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogIngresoReportes(
        fecha: widget.fecha,
        banco: banco,
        reportesApi: reportesApi,
      ),
    );

    if (actualizado == true) {
      await _cargarTotales();
    }
  }

  Color _colorBanco(String banco) {
    switch (banco) {
      case 'Santander':
        return Colors.red;
      case 'Mifel':
        return Colors.blue;
      case 'Monedero':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoBanco(String banco) {
    switch (banco) {
      case 'Santander':
        return Icons.account_balance_rounded;
      case 'Mifel':
        return Icons.credit_card_rounded;
      case 'Monedero':
        return Icons.wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Reportes de Tarjetas"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha seleccionada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.fecha,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _bancos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final banco = _bancos[index];
                        final color = _colorBanco(banco);
                        final total = _totales[banco] ?? 0;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _abrirIngresoReportes(banco),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _iconoBanco(banco),
                                      color: color,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          banco,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Total del día: ${_fmt(total)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReporteItem {
  final int? idReporte;
  final TextEditingController controller;
  final FocusNode focusNode;

  _ReporteItem({
    required this.idReporte,
    required this.controller,
    required this.focusNode,
  });
}

class _DialogIngresoReportes extends StatefulWidget {
  const _DialogIngresoReportes({
    required this.fecha,
    required this.banco,
    required this.reportesApi,
  });

  final String fecha;
  final String banco;
  final RegistroRepoApi reportesApi;

  @override
  State<_DialogIngresoReportes> createState() => _DialogIngresoReportesState();
}

class _DialogIngresoReportesState extends State<_DialogIngresoReportes> {
  final List<_ReporteItem> _items = [];
  bool _cargando = true;
  bool _guardando = false;
  double _total = 0;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _items.add(_nuevoItemVacio());
    _cargarDatos();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.controller.dispose();
      item.focusNode.dispose();
    }
    super.dispose();
  }

  _ReporteItem _nuevoItemVacio() {
    return _ReporteItem(
      idReporte: null,
      controller: TextEditingController(),
      focusNode: FocusNode(),
    );
  }

  _ReporteItem _itemDesdeBD({
    required int idReporte,
    required double importe,
  }) {
    return _ReporteItem(
      idReporte: idReporte,
      controller: TextEditingController(text: importe.toStringAsFixed(2)),
      focusNode: FocusNode(),
    );
  }

  String _fmt(double valor) => _currencyFormat.format(valor);

  double _parseToDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _cargarDatos() async {
    try {
      final rows = await widget.reportesApi.obtenerDetalle(
        fecha: widget.fecha,
        banco: widget.banco,
      );

      for (final item in _items) {
        item.controller.dispose();
        item.focusNode.dispose();
      }
      _items.clear();

      if (rows.isNotEmpty) {
        for (final row in rows) {
          _items.add(
            _itemDesdeBD(
              idReporte: row['idReporte'] as int,
              importe: _parseToDouble(row['importe']),
            ),
          );
        }
      }

      _items.add(_nuevoItemVacio());
      _recalcularTotal();

      if (mounted) {
        setState(() => _cargando = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar reportes: $e')),
      );
    }
  }

  void _recalcularTotal() {
    double suma = 0;
    for (final item in _items) {
      suma += _parseToDouble(item.controller.text);
    }
    if (mounted) {
      setState(() => _total = suma);
    }
  }

  void _onChangedCampo(int index, String value) {
    _recalcularTotal();

    if (index == _items.length - 1 &&
        _items[index].controller.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_nuevoItemVacio());
      });
    }
  }

  void _onSubmittedCampo(int index) {
    if (index == _items.length - 1 &&
        _items[index].controller.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_nuevoItemVacio());
      });

      Future.microtask(() {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_items[index + 1].focusNode);
      });
      return;
    }

    if (index + 1 < _items.length) {
      FocusScope.of(context).requestFocus(_items[index + 1].focusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  List<double> _obtenerImportesValidos() {
    final List<double> importes = [];
    for (final item in _items) {
      final value = double.tryParse(item.controller.text);
      if (value != null && value > 0) {
        importes.add(value);
      }
    }
    return importes;
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    final importes = _obtenerImportesValidos();

    if (importes.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    try {
      setState(() => _guardando = true);

      await widget.reportesApi.registrarReporte(
        fecha: widget.fecha,
        banco: widget.banco,
        importes: importes,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar reportes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: double.maxFinite,
        height: 560,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Reportes - ${widget.banco}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _guardando
                                  ? null
                                  : () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Fecha: ${widget.fecha}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final esUltimo = index == _items.length - 1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextField(
                                  controller: item.controller,
                                  focusNode: item.focusNode,
                                  enabled: !_guardando,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction: esUltimo
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Reporte ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) =>
                                      _onChangedCampo(index, value),
                                  onSubmitted: (_) => _onSubmittedCampo(index),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'TOTAL: ${_fmt(_total)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _guardando
                                    ? null
                                    : () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _guardando ? null : _guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Aceptar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_guardando)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 14),
                                Text(
                                  'Guardando reportes...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
