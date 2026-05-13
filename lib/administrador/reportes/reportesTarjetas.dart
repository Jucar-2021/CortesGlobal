import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/consumoPHP.dart';
import '../../api/documentos/consultaDocSumados_api.dart';

class ReporteTarjetas extends StatefulWidget {
  const ReporteTarjetas({
    super.key,
    required this.fechaini,
    required this.fechafin,
  });

  final String fechaini;
  final String fechafin;

  @override
  State<ReporteTarjetas> createState() => _ReporteTarjetasState();
}

class _ReporteTarjetasState extends State<ReporteTarjetas> {
  final ApiService apiService = ApiService();
  late final ConsultaBancosApi consultaBancosApi =
  ConsultaBancosApi(apiService);

  bool _cargando = true;
  String? _error;

  List<Map<String, dynamic>> _datos = [];
  List<Map<String, dynamic>> _datosR = [];

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  static const double _colFecha = 140;
  static const double _colMonto = 150;
  static const double _headerHeight = 52;
  static const double _rowHeight = 56;

  @override
  void initState() {
    super.initState();
    obtenerDatos(widget.fechaini, widget.fechafin);
  }

  double _parseToDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _fmt(double valor) => _currencyFormat.format(valor);

  Future<void> obtenerDatos(String fechaini, String fechafin) async {
    try {
      setState(() {
        _cargando = true;
        _error = null;
      });

      final datos = await consultaBancosApi.obtenerDocumentos(
        fechaIni: fechaini,
        fechaFin: fechafin,
      );

      final datosR = await consultaBancosApi.obtenerReportes(
        fechaIni: fechaini,
        fechaFin: fechafin,
      );

      if (!mounted) return;

      setState(() {
        _datos = datos;
        _datosR = datosR;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener datos: $error')),
      );
    }
  }

  List<Map<String, dynamic>> _combinarDatos() {
    final Map<String, Map<String, dynamic>> mapa = {};

    void agregarBanco({
      required String fecha,
      required int idBanco,
      required String nombreBanco,
      required double total,
      required bool esReporte,
    }) {
      mapa.putIfAbsent(fecha, () {
        return {
          'fecha': fecha,
          'bancos': <int, Map<String, dynamic>>{},
        };
      });

      final bancos = mapa[fecha]!['bancos'] as Map<int, Map<String, dynamic>>;

      bancos.putIfAbsent(idBanco, () {
        return {
          'idBanco': idBanco,
          'nombreBanco': nombreBanco,
          'corte': 0.0,
          'reporte': 0.0,
          'diferencia': 0.0,
        };
      });

      if (esReporte) {
        bancos[idBanco]!['reporte'] = total;
      } else {
        bancos[idBanco]!['corte'] = total;
      }

      final corte = _parseToDouble(bancos[idBanco]!['corte']);
      final reporte = _parseToDouble(bancos[idBanco]!['reporte']);

      bancos[idBanco]!['diferencia'] = corte - reporte;
    }

    for (final item in _datos) {
      final fecha = (item['fecha'] ?? '').toString();
      final idBanco = int.tryParse((item['idBanco'] ?? 0).toString()) ?? 0;
      final nombreBanco =
      (item['nombreBanco'] ?? item['banco'] ?? '').toString();
      final total = _parseToDouble(item['total']);

      if (fecha.isEmpty || idBanco <= 0 || nombreBanco.isEmpty) continue;

      agregarBanco(
        fecha: fecha,
        idBanco: idBanco,
        nombreBanco: nombreBanco,
        total: total,
        esReporte: false,
      );
    }

    for (final item in _datosR) {
      final fecha = (item['fecha'] ?? '').toString();
      final idBanco = int.tryParse((item['idBanco'] ?? 0).toString()) ?? 0;
      final nombreBanco =
      (item['nombreBanco'] ?? item['banco'] ?? '').toString();
      final total = _parseToDouble(item['total']);

      if (fecha.isEmpty || idBanco <= 0 || nombreBanco.isEmpty) continue;

      agregarBanco(
        fecha: fecha,
        idBanco: idBanco,
        nombreBanco: nombreBanco,
        total: total,
        esReporte: true,
      );
    }

    final lista = mapa.values.toList();

    lista.sort(
          (a, b) => a['fecha'].toString().compareTo(b['fecha'].toString()),
    );

    return lista;
  }

  List<Map<String, dynamic>> _obtenerBancosDinamicos(
      List<Map<String, dynamic>> comparados,
      ) {
    final Map<int, Map<String, dynamic>> bancos = {};

    for (final item in comparados) {
      final bancosFecha =
      item['bancos'] as Map<int, Map<String, dynamic>>;

      bancosFecha.forEach((idBanco, banco) {
        bancos[idBanco] = {
          'idBanco': idBanco,
          'nombreBanco': banco['nombreBanco'],
        };
      });
    }

    final lista = bancos.values.toList();

    lista.sort(
          (a, b) => a['nombreBanco']
          .toString()
          .compareTo(b['nombreBanco'].toString()),
    );

    return lista;
  }

  double _dif(double corte, double reporte) => corte - reporte;

  Color _colorDiferencia(double dif) {
    if (dif == 0) return Colors.green;
    if (dif > 0) return Colors.orange;
    return Colors.red;
  }

  IconData _iconoDiferencia(double dif) {
    if (dif == 0) return Icons.check_circle;
    if (dif > 0) return Icons.arrow_upward_rounded;
    return Icons.arrow_downward_rounded;
  }

  String _textoEstado(double dif) {
    if (dif == 0) return 'Cuadra';
    if (dif > 0) return 'Corte mayor';
    return 'Reporte mayor';
  }

  String _formatoFecha(String fecha) {
    try {
      final partes = fecha.split('-');
      if (partes.length != 3) return fecha;
      return '${partes[2]}-${partes[1]}-${partes[0]}';
    } catch (_) {
      return fecha;
    }
  }

  String _formatoFecha2(String fecha) {
    try {
      final partes = fecha.split('/');
      if (partes.length != 3) return fecha;
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    } catch (_) {
      return fecha;
    }
  }

  Widget _buildResumenCard({
    required String titulo,
    required double diferencia,
  }) {
    final color = _colorDiferencia(diferencia);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconoDiferencia(diferencia), color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _fmt(diferencia),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _textoEstado(diferencia),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile({
    required String titulo,
    required double valor,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fmt(valor),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int diasConDiferencia, int totalDias) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005498), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conciliación por rango',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoRangeTile(
                  'Fecha inicio',
                  _formatoFecha2(widget.fechaini),
                  Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoRangeTile(
                  'Fecha fin',
                  _formatoFecha2(widget.fechafin),
                  Icons.event_available_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Días con diferencia: $diasConDiferencia de $totalDias',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRangeTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: _headerHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF005498),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tableCell(
      String text,
      double width, {
        Color? color,
        FontWeight fontWeight = FontWeight.w600,
        double height = _rowHeight,
        Color? backgroundColor,
      }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: fontWeight,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDataRow(
      Map<String, dynamic> item,
      List<Map<String, dynamic>> bancos,
      ) {
    final bancosFecha =
    item['bancos'] as Map<int, Map<String, dynamic>>;

    bool hayDiferencia = false;

    for (final banco in bancos) {
      final idBanco = banco['idBanco'] as int;
      final datosBanco = bancosFecha[idBanco];

      final corte = _parseToDouble(datosBanco?['corte']);
      final reporte = _parseToDouble(datosBanco?['reporte']);
      final dif = _dif(corte, reporte);

      if (dif != 0) {
        hayDiferencia = true;
        break;
      }
    }

    final rowColor = hayDiferencia
        ? Colors.red.withOpacity(0.04)
        : Colors.green.withOpacity(0.04);

    final cells = <Widget>[
      Container(
        width: _colFecha,
        height: _rowHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hayDiferencia ? Icons.warning_amber_rounded : Icons.check_circle,
              color: hayDiferencia ? Colors.orange : Colors.green,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _formatoFecha('${item['fecha']}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    for (final banco in bancos) {
      final idBanco = banco['idBanco'] as int;
      final datosBanco = bancosFecha[idBanco];

      final corte = _parseToDouble(datosBanco?['corte']);
      final reporte = _parseToDouble(datosBanco?['reporte']);
      final dif = _parseToDouble(datosBanco?['diferencia']);

      cells.addAll([
        _tableCell(_fmt(corte), _colMonto, backgroundColor: rowColor),
        _tableCell(_fmt(reporte), _colMonto, backgroundColor: rowColor),
        _tableCell(
          _fmt(dif),
          _colMonto,
          color: _colorDiferencia(dif),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
      ]);
    }

    return Row(children: cells);
  }

  Widget _buildTotalRow(
      List<Map<String, dynamic>> bancos,
      Map<int, double> totalCorte,
      Map<int, double> totalReporte,
      Map<int, double> totalDiferencia,
      ) {
    const totalColor = Color(0xFF005498);
    const rowColor = Color(0xFFE8F1FB);

    final cells = <Widget>[
      _tableCell(
        'TOTAL',
        _colFecha,
        color: totalColor,
        fontWeight: FontWeight.bold,
        backgroundColor: rowColor,
      ),
    ];

    for (final banco in bancos) {
      final idBanco = banco['idBanco'] as int;

      cells.addAll([
        _tableCell(
          _fmt(totalCorte[idBanco] ?? 0),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalReporte[idBanco] ?? 0),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalDiferencia[idBanco] ?? 0),
          _colMonto,
          color: _colorDiferencia(totalDiferencia[idBanco] ?? 0),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
      ]);
    }

    return Row(children: cells);
  }

  Widget _buildTablaConHeaderFijo({
    required List<Map<String, dynamic>> comparados,
    required List<Map<String, dynamic>> bancos,
    required Map<int, double> totalCorte,
    required Map<int, double> totalReporte,
    required Map<int, double> totalDiferencia,
  }) {
    final totalWidth = _colFecha + (_colMonto * bancos.length * 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight = constraints.maxHeight - _headerHeight;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                Row(
                  children: [
                    _tableHeaderCell('Fecha', _colFecha),
                    for (final banco in bancos) ...[
                      _tableHeaderCell(
                        '${banco['nombreBanco']} Corte',
                        _colMonto,
                      ),
                      _tableHeaderCell(
                        '${banco['nombreBanco']} Terminal',
                        _colMonto,
                      ),
                      _tableHeaderCell(
                        'Dif. ${banco['nombreBanco']}',
                        _colMonto,
                      ),
                    ],
                  ],
                ),
                SizedBox(
                  height: bodyHeight > 0 ? bodyHeight : 300,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...comparados.map(
                                (item) => _buildDataRow(item, bancos),
                          ),
                          _buildTotalRow(
                            bancos,
                            totalCorte,
                            totalReporte,
                            totalDiferencia,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarTablaComparativa({
    required List<Map<String, dynamic>> comparados,
    required List<Map<String, dynamic>> bancos,
    required Map<int, double> totalCorte,
    required Map<int, double> totalReporte,
    required Map<int, double> totalDiferencia,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005498).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.table_chart_rounded,
                          color: Color(0xFF005498),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detalle tabular de conciliación',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005498),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildTablaConHeaderFijo(
                      comparados: comparados,
                      bancos: bancos,
                      totalCorte: totalCorte,
                      totalReporte: totalReporte,
                      totalDiferencia: totalDiferencia,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comparados = _combinarDatos();
    final bancos = _obtenerBancosDinamicos(comparados);

    final Map<int, double> totalCorte = {};
    final Map<int, double> totalReporte = {};
    final Map<int, double> totalDiferencia = {};

    for (final banco in bancos) {
      final idBanco = banco['idBanco'] as int;

      double corte = 0;
      double reporte = 0;

      for (final item in comparados) {
        final bancosFecha =
        item['bancos'] as Map<int, Map<String, dynamic>>;

        final datosBanco = bancosFecha[idBanco];

        if (datosBanco != null) {
          corte += _parseToDouble(datosBanco['corte']);
          reporte += _parseToDouble(datosBanco['reporte']);
        }
      }

      totalCorte[idBanco] = corte;
      totalReporte[idBanco] = reporte;
      totalDiferencia[idBanco] = _dif(corte, reporte);
    }

    final diasConDiferencia = comparados.where((item) {
      final bancosFecha =
      item['bancos'] as Map<int, Map<String, dynamic>>;

      for (final banco in bancos) {
        final idBanco = banco['idBanco'] as int;
        final datosBanco = bancosFecha[idBanco];

        final corte = _parseToDouble(datosBanco?['corte']);
        final reporte = _parseToDouble(datosBanco?['reporte']);

        if (_dif(corte, reporte) != 0) return true;
      }

      return false;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Conciliación de tarjetas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        )
            : comparados.isEmpty
            ? const Center(
          child: Text(
            'No se encontraron datos para el rango seleccionado.',
            textAlign: TextAlign.center,
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderCard(
                diasConDiferencia,
                comparados.length,
              ),
              const SizedBox(height: 18),

              for (final banco in bancos) ...[
                Row(
                  children: [
                    _buildKpiTile(
                      titulo: 'Corte ${banco['nombreBanco']}',
                      valor:
                      totalCorte[banco['idBanco']] ?? 0,
                      color: Colors.blue,
                      icon: Icons.credit_card_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildResumenCard(
                      titulo: 'Dif. ${banco['nombreBanco']}',
                      diferencia:
                      totalDiferencia[banco['idBanco']] ??
                          0,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF005498),
                      Color(0xFF1976D2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      _mostrarTablaComparativa(
                        comparados: comparados,
                        bancos: bancos,
                        totalCorte: totalCorte,
                        totalReporte: totalReporte,
                        totalDiferencia: totalDiferencia,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 18,
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Ver detalle tabular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}