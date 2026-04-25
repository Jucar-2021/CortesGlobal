import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/consumoPHP.dart';
import '../../api/cortes/verCorte_api.dart';
import '../../api/cortes/manejoCortes_api.dart';
import '../../tarjetasCajero/baucherCajero.dart';
import '../../clientes/listadoClientes.dart';

class ListadoCortes extends StatelessWidget {
  final String fecha;

  const ListadoCortes({super.key, required this.fecha});

  @override
  Widget build(BuildContext context) {
    return VisualizarCorte(fecha: fecha);
  }
}

class VisualizarCorte extends StatefulWidget {
  const VisualizarCorte({super.key, required this.fecha});
  final String fecha;

  @override
  State<VisualizarCorte> createState() => _VisualizarCorteState();
}

class _VisualizarCorteState extends State<VisualizarCorte> {
  late String fecha;

  final ApiService apiService = ApiService();
  late final VerCorteAPI verCorteAPI = VerCorteAPI(apiService);
  late final VerCorteAPI consumoClientesAPI = VerCorteAPI(apiService);
  late final ManejocortesApi manejoCortesAPI = ManejocortesApi(apiService);

  @override
  void initState() {
    super.initState();
    fecha = widget.fecha;
    setState(() {
      verCorteAPI.obtenerCortes(fecha: fecha);
    });
  }

  Future<List<dynamic>> _consumoClientes({
    required String idUsuario,
    required String fecha,
    required String producto,
  }) async {
    try {
      final data = await consumoClientesAPI.consumoClientes(
        idUsuario: idUsuario,
        fecha: fecha,
        producto: producto,
      );
      return data;
    } catch (e) {
      print("Error al obtener consumo de clientes: $e");
      return [];
    }
  }

  void _onEditarConcepto(
    BuildContext context, {
    required Map<String, dynamic> corte,
    required String concepto,
  }) {
    Navigator.pop(context);

    switch (concepto) {
      case "Santander":
        Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (_) => RegistroDocumentosPage(
                user: corte['usuario'].toString(),
                idUsuario: corte['idUsuario'],
                fecha: corte['fecha'].toString(),
                producto: corte['producto'].toString(),
                banco: 'Santander',
              ),
            ));
        break;
      case "Mifel":
        Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (_) => RegistroDocumentosPage(
                user: corte['usuario'].toString(),
                idUsuario: corte['idUsuario'],
                fecha: corte['fecha'].toString(),
                producto: corte['producto'].toString(),
                banco: 'Mifel',
              ),
            ));
        break;
      case "Monedero":
        Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (_) => RegistroDocumentosPage(
                user: corte['usuario'].toString(),
                idUsuario: corte['idUsuario'],
                fecha: corte['fecha'].toString(),
                producto: corte['producto'].toString(),
                banco: 'Monedero',
              ),
            ));
        break;
      case "Clientes":
        Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (_) => Listadoclientes(
                user: corte['usuario'].toString(),
                idUsuario: corte['idUsuario'],
                fecha: corte['fecha'].toString(),
                producto: corte['producto'].toString(),
              ),
            ));
        break;
      case "Global":
        Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (_) => RegistroDocumentosPage(
                user: corte['usuario'].toString(),
                idUsuario: corte['idUsuario'],
                fecha: corte['fecha'].toString(),
                producto: corte['producto'].toString(),
                banco: 'Cajero',
              ),
            ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFF005498),
          foregroundColor: Colors.white,
          title: Column(
            children: [
              const Text(
                "Cortes del día",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                fecha,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    verCorteAPI.obtenerCortes(fecha: fecha);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refrescando cortes...')),
                  );
                },
                icon: Icon(Icons.refresh))
          ]),
      body: FutureBuilder<List<dynamic>>(
        future: verCorteAPI.obtenerCortes(fecha: fecha),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            print("Error al obtener cortes: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade400,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Ocurrió un error al obtener los cortes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(22),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No se encontraron cortes para esta fecha.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            final cortes = snapshot.data!;

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF005498),
                        Color(0xFF1976D2),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Resumen del día",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Se encontraron ${cortes.length} corte(s)",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: cortes.length,
                    itemBuilder: (context, index) {
                      final corte = cortes[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.08),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              final consumoClientes = await _consumoClientes(
                                idUsuario: corte['idUsuario'].toString(),
                                fecha: fecha,
                                producto: corte['producto'].toString(),
                              );

                              _showCorteDetails(
                                context,
                                Map<String, dynamic>.from(corte),
                                consumoClientes,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF005498)
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF005498),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "${corte['usuario']}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.local_gas_station_rounded,
                                        label: "Producto",
                                        value: "${corte['producto']}",
                                        color: Colors.green,
                                      ),
                                      _buildInfoChip(
                                        icon: Icons.payments_rounded,
                                        label: "Efectivo entregado",
                                        value:
                                            "\$${corte['efectivoEntregado']}",
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: const Text(
                                      "Toca para ver el detalle completo del corte",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  String _fmt(double valor) => _currencyFormat.format(valor);

  double _parseToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }

  void _showCorteDetails(
    BuildContext context,
    Map<String, dynamic> corte,
    List<dynamic> consumoClientes,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Corte - ${corte['usuario']}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHighlightCard(
                          title: "Producto",
                          value: "${corte['producto']}",
                          icon: Icons.local_gas_station_rounded,
                          color: const Color(0xFF0B7A00),
                        ),
                        const SizedBox(height: 14),
                        _buildHighlightCard(
                          title: "Venta total",
                          value: _fmt(_parseToDouble(corte['venta'])),
                          icon: Icons.attach_money_rounded,
                          color: const Color(0xFF005498),
                          bigValue: true,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: "Tarjetas y clientes",
                          icon: Icons.credit_card_rounded,
                          children: [
                            _buildDetailRow(
                              "Santander",
                              _fmt(_parseToDouble(corte['santander'])),
                              showEditButton: true,
                              onEdit: () => _onEditarConcepto(
                                dialogContext,
                                corte: corte,
                                concepto: "Santander",
                              ),
                            ),
                            _buildDetailRow(
                              "Mifel",
                              _fmt(_parseToDouble(corte['mifel'])),
                              showEditButton: true,
                              onEdit: () => _onEditarConcepto(
                                dialogContext,
                                corte: corte,
                                concepto: "Mifel",
                              ),
                            ),
                            _buildDetailRow(
                              "Monedero",
                              _fmt(_parseToDouble(corte['monedero'])),
                              showEditButton: true,
                              onEdit: () => _onEditarConcepto(
                                dialogContext,
                                corte: corte,
                                concepto: "Monedero",
                              ),
                            ),
                            _buildDetailRow(
                              "Clientes",
                              _fmt(_parseToDouble(corte['clientes'])),
                              showEditButton: true,
                              onEdit: () => _onEditarConcepto(
                                dialogContext,
                                corte: corte,
                                concepto: "Clientes",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: "Depósitos y gastos",
                          icon: Icons.account_balance_wallet_rounded,
                          children: [
                            _buildDetailRow(
                              "Global",
                              _fmt(_parseToDouble(corte['depositos'])),
                              showEditButton: true,
                              onEdit: () => _onEditarConcepto(
                                dialogContext,
                                corte: corte,
                                concepto: "Global",
                              ),
                            ),
                            _buildDetailRow(
                              "Buzón",
                              _fmt(_parseToDouble(corte['buzon'])),
                            ),
                            _buildDetailRow(
                              "Gastos",
                              _fmt(_parseToDouble(corte['gastos'])),
                              valueColor: Colors.redAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: "Cuadre de efectivo",
                          icon: Icons.payments_rounded,
                          children: [
                            _buildDetailRow(
                              "Cuadre liquidación",
                              _fmt(_parseToDouble(corte['totalEfectivo'])),
                              valueColor: const Color(0xFFDD7200),
                              bold: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: "Detalle de clientes",
                          icon: Icons.groups_rounded,
                          children: consumoClientes.isNotEmpty
                              ? consumoClientes.map((cliente) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.person_rounded,
                                          size: 20,
                                          color: Colors.blueGrey,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "${cliente['razonSocial']}",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _fmt(_parseToDouble(
                                            cliente['importe'],
                                          )),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF005498),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()
                              : [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Sin consumo de clientes",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: dialogContext,
                        builder: (confirmContext) {
                          return AlertDialog(
                            title: const Text("Confirmar eliminación"),
                            content:
                                const Text("Esta acción no se puede deshacer."),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, false),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, true),
                                child: const Text("Eliminar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        try {
                          await manejoCortesAPI.eliminarCorte(
                            corte['idCorte'],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Corte eliminado exitosamente'),
                            ),
                          );
                          Navigator.pop(dialogContext);
                          setState(() {
                            verCorteAPI.obtenerCortes(fecha: fecha);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al eliminar el corte: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text("Eliminar corte"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text("Cerrar"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool bigValue = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.10),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: bigValue ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF005498)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005498),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color valueColor = Colors.black87,
    bool bold = false,
    bool showEditButton = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          if (showEditButton) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Editar $label',
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Color(0xFF005498),
              ),
              splashRadius: 20,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
