import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/consumoPHP.dart';
import '../api/documentos/consultaDocSumados_api.dart';

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

      setState(() {
        _datos = datos;
        _datosR = datosR;
        _cargando = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _cargando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener datos: $error')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _combinarDatos() {
    final Map<String, Map<String, dynamic>> mapa = {};

    for (final item in _datos) {
      final fecha = (item['fecha'] ?? '').toString();

      mapa[fecha] = {
        "fecha": fecha,
        "corteSantander": _parseToDouble(item['totalSantander']),
        "corteMifel": _parseToDouble(item['totalMifel']),
        "corteMonedero": _parseToDouble(item['totalMonedero']),
        "corteDepositos": _parseToDouble(item['totalDepositos']),
        "reporteSantander": 0.0,
        "reporteMifel": 0.0,
        "reporteMonedero": 0.0,
      };
    }

    for (final item in _datosR) {
      final fecha = (item['fecha'] ?? '').toString();

      mapa.putIfAbsent(fecha, () {
        return {
          "fecha": fecha,
          "corteSantander": 0.0,
          "corteMifel": 0.0,
          "corteMonedero": 0.0,
          "corteDepositos": 0.0,
          "reporteSantander": 0.0,
          "reporteMifel": 0.0,
          "reporteMonedero": 0.0,
        };
      });

      mapa[fecha]!["reporteSantander"] = _parseToDouble(item['totalSantander']);
      mapa[fecha]!["reporteMifel"] = _parseToDouble(item['totalMifel']);
      mapa[fecha]!["reporteMonedero"] = _parseToDouble(item['totalMonedero']);
    }

    final lista = mapa.values.toList();
    lista
        .sort((a, b) => a['fecha'].toString().compareTo(b['fecha'].toString()));
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconoDiferencia(diferencia), color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _fmt(diferencia),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
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

  Widget _buildDataRow(Map<String, dynamic> item) {
    final corteSant = _parseToDouble(item['corteSantander']);
    final repSant = _parseToDouble(item['reporteSantander']);
    final difSant = _dif(corteSant, repSant);

    final corteMifel = _parseToDouble(item['corteMifel']);
    final repMifel = _parseToDouble(item['reporteMifel']);
    final difMifel = _dif(corteMifel, repMifel);

    final corteMon = _parseToDouble(item['corteMonedero']);
    final repMon = _parseToDouble(item['reporteMonedero']);
    final difMon = _dif(corteMon, repMon);

    final deposito = _parseToDouble(item['corteDepositos']);

    final hayDiferencia = difSant != 0 || difMifel != 0 || difMon != 0;
    final rowColor = hayDiferencia
        ? Colors.red.withOpacity(0.04)
        : Colors.green.withOpacity(0.04);

    return Row(
      children: [
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
                hayDiferencia
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
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
        _tableCell(_fmt(corteSant), _colMonto, backgroundColor: rowColor),
        _tableCell(_fmt(repSant), _colMonto, backgroundColor: rowColor),
        _tableCell(
          _fmt(difSant),
          _colMonto,
          color: _colorDiferencia(difSant),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(_fmt(corteMifel), _colMonto, backgroundColor: rowColor),
        _tableCell(_fmt(repMifel), _colMonto, backgroundColor: rowColor),
        _tableCell(
          _fmt(difMifel),
          _colMonto,
          color: _colorDiferencia(difMifel),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(_fmt(corteMon), _colMonto, backgroundColor: rowColor),
        _tableCell(_fmt(repMon), _colMonto, backgroundColor: rowColor),
        _tableCell(
          _fmt(difMon),
          _colMonto,
          color: _colorDiferencia(difMon),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(deposito),
          _colMonto,
          color: Colors.orange.shade800,
          backgroundColor: rowColor,
        ),
      ],
    );
  }

  Widget _buildTotalRow({
    required double totalCorteSantander,
    required double totalReporteSantander,
    required double totalDifSantander,
    required double totalCorteMifel,
    required double totalReporteMifel,
    required double totalDifMifel,
    required double totalCorteMonedero,
    required double totalReporteMonedero,
    required double totalDifMonedero,
    required double totalDepositos,
  }) {
    const totalColor = Color(0xFF005498);
    const rowColor = Color(0xFFE8F1FB);

    return Row(
      children: [
        _tableCell(
          'TOTAL',
          _colFecha,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalCorteSantander),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalReporteSantander),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalDifSantander),
          _colMonto,
          color: _colorDiferencia(totalDifSantander),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalCorteMifel),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalReporteMifel),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalDifMifel),
          _colMonto,
          color: _colorDiferencia(totalDifMifel),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalCorteMonedero),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalReporteMonedero),
          _colMonto,
          color: totalColor,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalDifMonedero),
          _colMonto,
          color: _colorDiferencia(totalDifMonedero),
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
        _tableCell(
          _fmt(totalDepositos),
          _colMonto,
          color: Colors.orange.shade800,
          fontWeight: FontWeight.bold,
          backgroundColor: rowColor,
        ),
      ],
    );
  }

  Widget _buildTablaConHeaderFijo({
    required BuildContext context,
    required List<Map<String, dynamic>> comparados,
    required double totalCorteSantander,
    required double totalReporteSantander,
    required double totalDifSantander,
    required double totalCorteMifel,
    required double totalReporteMifel,
    required double totalDifMifel,
    required double totalCorteMonedero,
    required double totalReporteMonedero,
    required double totalDifMonedero,
    required double totalDepositos,
  }) {
    final totalWidth = _colFecha + (_colMonto * 10);

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
                    _tableHeaderCell('Sant. Corte', _colMonto),
                    _tableHeaderCell('Sant. Terminal', _colMonto),
                    _tableHeaderCell('Dif. Sant.', _colMonto),
                    _tableHeaderCell('Mifel Corte', _colMonto),
                    _tableHeaderCell('Mifel Terminal', _colMonto),
                    _tableHeaderCell('Dif. Mifel', _colMonto),
                    _tableHeaderCell('Moned. Corte', _colMonto),
                    _tableHeaderCell('Moned. Terminal', _colMonto),
                    _tableHeaderCell('Dif. Moned.', _colMonto),
                    _tableHeaderCell('Cajero Global', _colMonto),
                  ],
                ),
                SizedBox(
                  height: bodyHeight > 0 ? bodyHeight : 300,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...comparados.map(_buildDataRow),
                          _buildTotalRow(
                            totalCorteSantander: totalCorteSantander,
                            totalReporteSantander: totalReporteSantander,
                            totalDifSantander: totalDifSantander,
                            totalCorteMifel: totalCorteMifel,
                            totalReporteMifel: totalReporteMifel,
                            totalDifMifel: totalDifMifel,
                            totalCorteMonedero: totalCorteMonedero,
                            totalReporteMonedero: totalReporteMonedero,
                            totalDifMonedero: totalDifMonedero,
                            totalDepositos: totalDepositos,
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
    required double totalCorteSantander,
    required double totalReporteSantander,
    required double totalDifSantander,
    required double totalCorteMifel,
    required double totalReporteMifel,
    required double totalDifMifel,
    required double totalCorteMonedero,
    required double totalReporteMonedero,
    required double totalDifMonedero,
    required double totalDepositos,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildTablaConHeaderFijo(
                      context: sheetContext,
                      comparados: comparados,
                      totalCorteSantander: totalCorteSantander,
                      totalReporteSantander: totalReporteSantander,
                      totalDifSantander: totalDifSantander,
                      totalCorteMifel: totalCorteMifel,
                      totalReporteMifel: totalReporteMifel,
                      totalDifMifel: totalDifMifel,
                      totalCorteMonedero: totalCorteMonedero,
                      totalReporteMonedero: totalReporteMonedero,
                      totalDifMonedero: totalDifMonedero,
                      totalDepositos: totalDepositos,
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

    final totalCorteSantander = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['corteSantander']),
    );
    final totalCorteMifel = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['corteMifel']),
    );
    final totalCorteMonedero = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['corteMonedero']),
    );
    final totalDepositos = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['corteDepositos']),
    );

    final totalReporteSantander = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['reporteSantander']),
    );
    final totalReporteMifel = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['reporteMifel']),
    );
    final totalReporteMonedero = comparados.fold<double>(
      0,
      (sum, item) => sum + _parseToDouble(item['reporteMonedero']),
    );

    final totalDifSantander = _dif(totalCorteSantander, totalReporteSantander);
    final totalDifMifel = _dif(totalCorteMifel, totalReporteMifel);
    final totalDifMonedero = _dif(totalCorteMonedero, totalReporteMonedero);

    final diasConDiferencia = comparados.where((item) {
      final ds = _dif(
        _parseToDouble(item['corteSantander']),
        _parseToDouble(item['reporteSantander']),
      );
      final dm = _dif(
        _parseToDouble(item['corteMifel']),
        _parseToDouble(item['reporteMifel']),
      );
      final dmo = _dif(
        _parseToDouble(item['corteMonedero']),
        _parseToDouble(item['reporteMonedero']),
      );
      return ds != 0 || dm != 0 || dmo != 0;
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
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  )
                : comparados.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron datos para el rango seleccionado.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                            Row(
                              children: [
                                _buildKpiTile(
                                  titulo: 'Corte Santander',
                                  valor: totalCorteSantander,
                                  color: Colors.red,
                                  icon: Icons.account_balance_rounded,
                                ),
                                const SizedBox(width: 10),
                                _buildResumenCard(
                                  titulo: 'Dif. Santander',
                                  diferencia: totalDifSantander,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildKpiTile(
                                  titulo: 'Corte Mifel',
                                  valor: totalCorteMifel,
                                  color: Colors.blue,
                                  icon: Icons.credit_card_rounded,
                                ),
                                const SizedBox(width: 10),
                                _buildResumenCard(
                                  titulo: 'Dif. Mifel',
                                  diferencia: totalDifMifel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildKpiTile(
                                  titulo: 'Corte Monedero',
                                  valor: totalCorteMonedero,
                                  color: Colors.green,
                                  icon: Icons.wallet_rounded,
                                ),
                                const SizedBox(width: 10),
                                _buildResumenCard(
                                  titulo: 'Dif. Monedero',
                                  diferencia: totalDifMonedero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildKpiTile(
                                  titulo: 'Cajero Global',
                                  valor: totalDepositos,
                                  color: Colors.orange,
                                  icon: Icons.payments_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF005498),
                                    Color(0xFF1976D2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    _mostrarTablaComparativa(
                                      comparados: comparados,
                                      totalCorteSantander: totalCorteSantander,
                                      totalReporteSantander:
                                          totalReporteSantander,
                                      totalDifSantander: totalDifSantander,
                                      totalCorteMifel: totalCorteMifel,
                                      totalReporteMifel: totalReporteMifel,
                                      totalDifMifel: totalDifMifel,
                                      totalCorteMonedero: totalCorteMonedero,
                                      totalReporteMonedero:
                                          totalReporteMonedero,
                                      totalDifMonedero: totalDifMonedero,
                                      totalDepositos: totalDepositos,
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
