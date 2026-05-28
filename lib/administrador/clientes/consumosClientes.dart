import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cortes/listadoCortes.dart';
import '../../api/client/consumos_api.dart';
import '../../api/consumoPHP.dart';

class ClienteSaldos extends StatefulWidget {
  const ClienteSaldos({
    super.key,
    required this.fecha,
  });

  final String fecha;

  @override
  State<ClienteSaldos> createState() => _ClienteSaldosState();
}

class _ClienteSaldosState extends State<ClienteSaldos> {
  final ApiService apiService = ApiService();

  late final ConsumosApi consumosApi;

  late Future<List<Map<String, dynamic>>> _futureConsumos;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  String _fmt(double valor) {
    return _currencyFormat.format(valor);
  }

  @override
  void initState() {
    super.initState();

    consumosApi = ConsumosApi(apiService);

    _futureConsumos = _fetchConsumos(widget.fecha);
  }

  Future<List<Map<String, dynamic>>> _fetchConsumos(
      String fecha,
      ) async {
    try {
      return await consumosApi.getConsumos(
        fecha: fecha,
      );
    } catch (e) {
      if (!mounted) return [];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al obtener consumos: $e',
          ),
        ),
      );

      return [];
    }
  }

  Future<void> _recargar() async {
    setState(() {
      _futureConsumos = _fetchConsumos(widget.fecha);
    });
  }

  List<Map<String, dynamic>> _agruparPorCliente(
      List<Map<String, dynamic>> consumos,
      ) {
    final Map<String, Map<String, dynamic>> agrupados = {};

    for (final consumo in consumos) {
      final razonSocial =
      (consumo['razonSocial'] ?? 'Cliente sin nombre')
          .toString()
          .trim();

      final importe =
          double.tryParse(consumo['importe'].toString()) ?? 0;

      if (!agrupados.containsKey(razonSocial)) {
        agrupados[razonSocial] = {
          'razonSocial': razonSocial,
          'total': 0.0,
          'cargas': <Map<String, dynamic>>[],
        };
      }

      agrupados[razonSocial]!['total'] =
          (agrupados[razonSocial]!['total'] as double) +
              importe;

      (agrupados[razonSocial]!['cargas']
      as List<Map<String, dynamic>>)
          .add({
        ...consumo,
        'importe': importe,
      });
    }

    final clientes = agrupados.values.toList();

    clientes.sort((a, b) {
      return a['razonSocial']
          .toString()
          .toLowerCase()
          .compareTo(
        b['razonSocial']
            .toString()
            .toLowerCase(),
      );
    });

    return clientes;
  }

  double _totalGeneral(
      List<Map<String, dynamic>> clientes,
      ) {
    return clientes.fold(
      0.0,
          (total, cliente) {
        return total +
            ((cliente['total'] as double?) ?? 0);
      },
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

  Color _colorTurno(String turno) {
    switch (turno.toLowerCase()) {
      case 'mañana':
      case 'manana':
        return Colors.orange.shade700;

      case 'tarde':
        return Colors.blue.shade700;

      case 'noche':
        return Colors.indigo.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  Widget _itemResumen({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icono,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),

          Flexible(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  valor,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenSuperior(
      List<Map<String, dynamic>> clientes,
      ) {
    final total = _totalGeneral(clientes);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900,
            Colors.indigo.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _itemResumen(
            icono: Icons.groups_rounded,
            titulo: 'Clientes',
            valor: clientes.length.toString(),
          ),

          _itemResumen(
            icono: Icons.payments_rounded,
            titulo: 'Total saldos',
            valor: _fmt(total),
          ),

          _itemResumen(
            icono: Icons.calendar_month_rounded,
            titulo: 'Fecha',
            valor: _formatoFecha2(widget.fecha),
          ),
        ],
      ),
    );
  }

  Widget _chipInfo({
    required IconData icono,
    required String texto,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 15,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargaItem({
    required Map<String, dynamic> carga,
    required int numeroCarga,
  }) {
    final nombreUsuario =
    (carga['nombreUsuario'] ?? 'Sin usuario')
        .toString();

    final turno =
    (carga['turno'] ?? 'Sin turno').toString();

    final importe =
        double.tryParse(carga['importe'].toString()) ??
            0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.green.shade50.withOpacity(0.50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade700,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numeroCarga.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Carga $numeroCarga',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _chipInfo(
                      icono: Icons.person_rounded,
                      texto: nombreUsuario,
                      color: Colors.purple.shade700,
                    ),

                    _chipInfo(
                      icono:
                      Icons.access_time_filled_rounded,
                      texto: turno,
                      color: _colorTurno(turno),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(importe),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Importe',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(
      Map<String, dynamic> cliente,
      ) {
    final razonSocial =
    cliente['razonSocial'].toString();

    final total =
        (cliente['total'] as double?) ?? 0;

    final cargas =
    cliente['cargas'] as List<Map<String, dynamic>>;

    cargas.sort((a, b) {
      final turnoA =
      (a['turno'] ?? '').toString();

      final turnoB =
      (b['turno'] ?? '').toString();

      return turnoA.compareTo(turnoB);
    });

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          childrenPadding:
          const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            14,
          ),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.indigo.shade700,
                ],
              ),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          title: Text(
            razonSocial,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
            ),
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),

                const SizedBox(width: 5),

                Text(
                  '${cargas.length} carga(s)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          trailing: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(total),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          children: [
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 10),

            for (int i = 0;
            i < cargas.length;
            i++)
              _buildCargaItem(
                carga: cargas[i],
                numeroCarga: i + 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<
        List<Map<String, dynamic>>>(
      future: _futureConsumos,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No hay consumos para esta fecha',
            ),
          );
        }

        final clientes =
        _agruparPorCliente(snapshot.data!);

        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 90,
            ),
            itemCount: clientes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildResumenSuperior(
                  clientes,
                );
              }

              final cliente =
              clientes[index - 1];

              return _buildClienteCard(
                cliente,
              );
            },
          ),
        );
      },
    );
  }

  void _accionFloatingButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ListadoCortes(
              fecha: widget.fecha,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F7FB,
      ),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        title: const Text(
          'Saldos de Clientes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _recargar,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: _buildBody(),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor:
        Colors.indigo.shade700,
        elevation: 5,
        onPressed: _accionFloatingButton,
        icon: const Icon(
          Icons.list_alt_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'Ver cortes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}