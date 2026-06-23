import 'package:flutter/material.dart';
import '../../api/consumoPHP.dart';
import '../../api/documentos/efectivo_api.dart';

class Buzonefectivo extends StatefulWidget {
  const Buzonefectivo({
    super.key,
    required this.fechaIni,
    required this.fechaFin,
  });

  final String fechaIni;
  final String fechaFin;

  @override
  State<Buzonefectivo> createState() => _BuzonefectivoState();
}

class _BuzonefectivoState extends State<Buzonefectivo> {
  final ApiService apiServise = ApiService();
  late final ConsultaEfectivoApi api;

  bool cargando = true;
  String? error;

  List<Map<String, dynamic>> resumen = [];

  double totalCajeroGeneral = 0;
  double totalBuzonGeneral = 0;

  @override
  void initState() {
    super.initState();
    api = ConsultaEfectivoApi(apiServise);
    fechDatos();
  }

  Future<void> fechDatos() async {
    try {
      setState(() {
        cargando = true;
        error = null;
      });

      final buzon = await obtenerBuzon(
        fechaIni: widget.fechaIni,
        fechaFin: widget.fechaFin,
      );

      final cajero = await obtenerCajero(
        fechaIni: widget.fechaIni,
        fechaFin: widget.fechaFin,
      );

      final datosAgrupados = _agruparDatos(buzon: buzon, cajero: cajero);

      setState(() {
        resumen = datosAgrupados;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al traer los datos: $e';
        cargando = false;
      });
    }
  }

  List<Map<String, dynamic>> _agruparDatos({
    required List<Map<String, dynamic>> buzon,
    required List<Map<String, dynamic>> cajero,
  }) {
    final Map<int, Map<String, dynamic>> agrupado = {};

    totalCajeroGeneral = 0;
    totalBuzonGeneral = 0;

    for (final item in cajero) {
      final idUsuario = int.tryParse(item['idUsuario'].toString()) ?? 0;
      final nombreUsuario = item['nombreUsuario']?.toString() ?? 'Sin usuario';
      final importe = double.tryParse(item['importe'].toString()) ?? 0;

      if (idUsuario == 0) continue;

      agrupado.putIfAbsent(idUsuario, () {
        return {
          'idUsuario': idUsuario,
          'nombreUsuario': nombreUsuario,
          'totalCajero': 0.0,
          'totalBuzon': 0.0,
        };
      });

      agrupado[idUsuario]!['totalCajero'] += importe;
      totalCajeroGeneral += importe;
    }

    for (final item in buzon) {
      final idUsuario = int.tryParse(item['idUsuario'].toString()) ?? 0;
      final nombreUsuario = item['nombreUsuario']?.toString() ?? 'Sin usuario';
      final importe = double.tryParse(item['importe'].toString()) ?? 0;

      if (idUsuario == 0) continue;

      agrupado.putIfAbsent(idUsuario, () {
        return {
          'idUsuario': idUsuario,
          'nombreUsuario': nombreUsuario,
          'totalCajero': 0.0,
          'totalBuzon': 0.0,
        };
      });

      agrupado[idUsuario]!['totalBuzon'] += importe;
      totalBuzonGeneral += importe;
    }

    return agrupado.values.toList();
  }

  Future<List<Map<String, dynamic>>> obtenerBuzon({
    required String fechaIni,
    required String fechaFin,
  }) async {
    return api.obtenerBuzon(fechaIni: fechaIni, fechaFin: fechaFin);
  }

  Future<List<Map<String, dynamic>>> obtenerCajero({
    required String fechaIni,
    required String fechaFin,
  }) async {
    return api.obtenerCajero(fechaIni: fechaIni, fechaFin: fechaFin);
  }

  String _moneda(dynamic valor) {
    final numero = double.tryParse(valor.toString()) ?? 0;
    return '\$${numero.toStringAsFixed(2)}';
  }

  Widget _buildTabla() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF005498)),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Total cajero')),
          DataColumn(label: Text('Total buzón')),
        ],
        rows: [
          ...resumen.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item['nombreUsuario'].toString())),
                DataCell(Text(_moneda(item['totalCajero']))),
                DataCell(Text(_moneda(item['totalBuzon']))),
              ],
            );
          }),

          DataRow(
            color: WidgetStateProperty.all(Colors.blue.shade50),
            cells: [
              const DataCell(
                Text(
                  'TOTAL GENERAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  _moneda(totalCajeroGeneral),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  _moneda(totalBuzonGeneral),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoConsulta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF005498)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Periodo consultado: ${_formatoFecha2(widget.fechaIni)} al ${_formatoFecha2(widget.fechaFin)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF005498),
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Buzón y Cajero'),
        centerTitle: true,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: fechDatos, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error!, textAlign: TextAlign.center),
                ),
              )
            : resumen.isEmpty
            ? const Center(child: Text('No hay datos registrados'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPeriodoConsulta(),

                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _buildTabla(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
