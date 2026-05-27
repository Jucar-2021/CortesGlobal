import 'package:flutter/material.dart';
import '../../api/documentos/generalTPV_api.dart';
import '../../api/consumoPHP.dart';
import 'package:intl/intl.dart';

class DetalleTPV extends StatefulWidget {
  const DetalleTPV({super.key, required this.fecha});

  final String fecha;

  @override
  State<DetalleTPV> createState() => _DetalleTPVState();
}

class _DetalleTPVState extends State<DetalleTPV> {
  final ApiService apiServise = ApiService();
  late final GenetalTPVapi api;

  bool cargando = true;

  List<Map<String, dynamic>> cobrosOriginales = [];
  List<Map<String, dynamic>> cobrosFiltrados = [];

  final TextEditingController buscarImporteController = TextEditingController();

  final Set<String> usuariosSeleccionados = {};
  final Set<String> bancosSeleccionados = {};
  final Set<String> turnosSeleccionados = {};

  @override
  void initState() {
    super.initState();
    api = GenetalTPVapi(apiServise);
    cargarCobros();
  }

  Future<void> cargarCobros() async {
    setState(() => cargando = true);

    try {
      final datos = await api.getCobrosTPV(fecha: widget.fecha);

      setState(() {
        cobrosOriginales = datos;
        cobrosFiltrados = datos;
        cargando = false;
      });

      aplicarFiltros();
    } catch (e) {
      setState(() => cargando = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar cobros: $e')),
      );
    }
  }

  void aplicarFiltros() {
    final textoImporte = buscarImporteController.text.trim().toLowerCase();

    final resultado = cobrosOriginales.where((cobro) {
      final nombreUsuario = (cobro['nombreUsuario'] ?? '').toString();
      final nombreBanco = (cobro['nombreBanco'] ?? '').toString();
      final turno = (cobro['turno'] ?? '').toString();
      final importe = (cobro['importe'] ?? '').toString().toLowerCase();

      final coincideUsuario = usuariosSeleccionados.isEmpty ||
          usuariosSeleccionados.contains(nombreUsuario);

      final coincideBanco = bancosSeleccionados.isEmpty ||
          bancosSeleccionados.contains(nombreBanco);

      final coincideTurno =
          turnosSeleccionados.isEmpty || turnosSeleccionados.contains(turno);

      final coincideImporte =
          textoImporte.isEmpty || importe.contains(textoImporte);

      return coincideUsuario &&
          coincideBanco &&
          coincideTurno &&
          coincideImporte;
    }).toList();

    setState(() {
      cobrosFiltrados = resultado;
    });
  }

  List<String> obtenerUsuarios() {
    return cobrosOriginales
        .map((e) => (e['nombreUsuario'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> obtenerBancos() {
    return cobrosOriginales
        .map((e) => (e['nombreBanco'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> obtenerTurnos() {
    return cobrosOriginales
        .map((e) => (e['turno'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Map<String, dynamic>> obtenerBancosDisponibles() {
    final Map<int, Map<String, dynamic>> bancos = {};

    for (final cobro in cobrosOriginales) {
      final idBanco = int.tryParse(cobro['idBanco'].toString()) ?? 0;
      final nombreBanco = (cobro['nombreBanco'] ?? '').toString();

      if (idBanco > 0 && nombreBanco.isNotEmpty) {
        bancos[idBanco] = {
          'idBanco': idBanco,
          'nombreBanco': nombreBanco,
        };
      }
    }

    return bancos.values.toList()
      ..sort(
            (a, b) => a['nombreBanco']
            .toString()
            .compareTo(b['nombreBanco'].toString()),
      );
  }

  double obtenerTotalMostrado() {
    return cobrosFiltrados.fold(0.0, (total, cobro) {
      final importe = double.tryParse(cobro['importe'].toString()) ?? 0;
      return total + importe;
    });
  }

  bool get hayFiltrosActivos {
    return usuariosSeleccionados.isNotEmpty ||
        bancosSeleccionados.isNotEmpty ||
        turnosSeleccionados.isNotEmpty ||
        buscarImporteController.text.trim().isNotEmpty;
  }

  Future<void> actualizarBanco({
    required int idCobro,
    required int idBancoNuevo,
  }) async {
    try {
      await api.actualizarBanco(
        idCobro: idCobro,
        idBancoNuevo: idBancoNuevo,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banco actualizado correctamente')),
      );

      await cargarCobros();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el banco: $e')),
      );
    }
  }

  Future<void> actualizarImporte({
    required int idCobro,
    required double nuevoImporte,
  }) async {
    try {
      await api.actualizarImporte(
        idCobro: idCobro,
        nuevoImporte: nuevoImporte,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importe actualizado correctamente')),
      );

      await cargarCobros();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el importe: $e')),
      );
    }
  }

  Future<void> eliminarCobro({required int idCobro}) async {
    try {
      await api.eliminarCobro(idCobro: idCobro);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro eliminado correctamente')),
      );

      await cargarCobros();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el cobro: $e')),
      );
    }
  }

  void limpiarFiltros() {
    setState(() {
      usuariosSeleccionados.clear();
      bancosSeleccionados.clear();
      turnosSeleccionados.clear();
      buscarImporteController.clear();
      cobrosFiltrados = cobrosOriginales;
    });
  }

  void mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void actualizarModal() {
              setModalState(() {});
              aplicarFiltros();
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.filter_alt),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Filtros de cobros',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          construirFiltrosModal(
                            titulo: 'Usuarios',
                            icono: Icons.person,
                            opciones: obtenerUsuarios(),
                            seleccionados: usuariosSeleccionados,
                            onChanged: actualizarModal,
                          ),
                          const SizedBox(height: 12),
                          construirFiltrosModal(
                            titulo: 'Bancos',
                            icono: Icons.account_balance,
                            opciones: obtenerBancos(),
                            seleccionados: bancosSeleccionados,
                            onChanged: actualizarModal,
                          ),
                          const SizedBox(height: 12),
                          construirFiltrosModal(
                            titulo: 'Turnos',
                            icono: Icons.schedule,
                            opciones: obtenerTurnos(),
                            seleccionados: turnosSeleccionados,
                            onChanged: actualizarModal,
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  limpiarFiltros();
                                  setModalState(() {});
                                },
                                icon: const Icon(Icons.cleaning_services),
                                label: const Text('Limpiar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.check),
                                label: const Text('Aplicar'),
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
          },
        );
      },
    );
  }

  Widget construirFiltrosModal({
    required String titulo,
    required IconData icono,
    required List<String> opciones,
    required Set<String> seleccionados,
    required VoidCallback onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        leading: Icon(icono),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          seleccionados.isEmpty
              ? 'Sin selección'
              : '${seleccionados.length} seleccionado(s)',
        ),
        children: opciones.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay opciones disponibles'),
          ),
        ]
            : opciones.map((opcion) {
          return CheckboxListTile(
            value: seleccionados.contains(opcion),
            title: Text(opcion),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              if (value == true) {
                seleccionados.add(opcion);
              } else {
                seleccionados.remove(opcion);
              }

              onChanged();
            },
          );
        }).toList(),
      ),
    );
  }

  void mostrarDialogoEditarImporte(Map<String, dynamic> cobro) {
    final controller = TextEditingController(
      text: cobro['importe'].toString(),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Actualizar importe'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nuevo importe',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoImporte = double.tryParse(controller.text.trim());

                if (nuevoImporte == null || nuevoImporte < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Importe inválido')),
                  );
                  return;
                }

                Navigator.pop(context);

                await actualizarImporte(
                  idCobro: int.parse(cobro['idCobro'].toString()),
                  nuevoImporte: nuevoImporte,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void mostrarDialogoEditarBanco(Map<String, dynamic> cobro) {
    final bancos = obtenerBancosDisponibles();

    if (bancos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay bancos disponibles')),
      );
      return;
    }

    int bancoSeleccionado = int.tryParse(cobro['idBanco'].toString()) ?? 0;

    final existeBanco = bancos.any((b) => b['idBanco'] == bancoSeleccionado);
    if (!existeBanco) {
      bancoSeleccionado = bancos.first['idBanco'];
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Actualizar banco'),
              content: DropdownButtonFormField<int>(
                value: bancoSeleccionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Banco',
                  border: OutlineInputBorder(),
                ),
                items: bancos.map((banco) {
                  return DropdownMenuItem<int>(
                    value: banco['idBanco'],
                    child: Text(banco['nombreBanco']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => bancoSeleccionado = value);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    await actualizarBanco(
                      idCobro: int.parse(cobro['idCobro'].toString()),
                      idBancoNuevo: bancoSeleccionado,

                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  String _fmt(double valor) => _currencyFormat.format(valor);

  Widget construirResumen() {
    final total = obtenerTotalMostrado();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        runSpacing: 14,
        spacing: 14,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _itemResumen(
            titulo: 'Cobros mostrados',
            valor: cobrosFiltrados.length.toString(),
            icono: Icons.receipt_long,
          ),
          _itemResumen(
            titulo: 'Total mostrado',
            valor: '${_fmt(total)}',
            icono: Icons.payments,
          ),
          _itemResumen(
            titulo: 'Fecha',
            valor: _formatoFecha2(widget.fecha),
            icono: Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _itemResumen({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Icon(icono, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
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

  Widget construirBuscadorYAcciones() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: buscarImporteController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Buscar importe',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                suffixIcon: buscarImporteController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    buscarImporteController.clear();
                    aplicarFiltros();
                  },
                )
                    : null,
              ),
              onChanged: (_) => aplicarFiltros(),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.filled(
                onPressed: mostrarFiltros,
                icon: const Icon(Icons.filter_alt),
                tooltip: 'Filtros',
              ),
              if (hayFiltrosActivos)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget construirCardCobro(Map<String, dynamic> cobro) {
    final idCobro = cobro['idCobro'];
    final nombreUsuario = cobro['nombreUsuario'] ?? 'Sin usuario';
    final nombreBanco = cobro['nombreBanco'] ?? 'Sin banco';
    final turno = cobro['turno'] ?? 'Sin turno';
    final fecha = cobro['fecha'] ?? widget.fecha;
    final importe = double.tryParse(cobro['importe'].toString()) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreUsuario.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chipInfo(
                            icono: Icons.account_balance,
                            texto: nombreBanco.toString(),
                          ),
                          _chipInfo(
                            icono: Icons.schedule,
                            texto: turno.toString(),
                          ),
                          _chipInfo(
                            icono: Icons.calendar_today,
                            texto: _formatoFecha1(fecha.toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '\$ ${importe.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final usarBotonesGrandes = constraints.maxWidth > 360;

                if (usarBotonesGrandes) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => mostrarDialogoEditarBanco(cobro),
                          icon: const Icon(Icons.account_balance),
                          label: const Text('Banco'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => mostrarDialogoEditarImporte(cobro),
                          icon: const Icon(Icons.edit),
                          label: const Text('Importe'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => confirmarEliminar(idCobro),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    IconButton.outlined(
                      tooltip: 'Cambiar banco',
                      onPressed: () => mostrarDialogoEditarBanco(cobro),
                      icon: const Icon(Icons.account_balance),
                    ),
                    IconButton.outlined(
                      tooltip: 'Editar importe',
                      onPressed: () => mostrarDialogoEditarImporte(cobro),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton.outlined(
                      tooltip: 'Eliminar',
                      onPressed: () => confirmarEliminar(idCobro),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo({
    required IconData icono,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void confirmarEliminar(dynamic idCobro) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar cobro'),
          content: Text('¿Deseas eliminar el cobro #$idCobro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                await eliminarCobro(
                  idCobro: int.parse(idCobro.toString()),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    buscarImporteController.dispose();
    super.dispose();
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

  String _formatoFecha1(String fecha) {
    try {
      final partes = fecha.split('-');
      if (partes.length != 3) return fecha;
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detalle de Cobros TPV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarCobros,
          ),
        ],
      ),
      body: SafeArea(
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : cobrosOriginales.isEmpty
            ? const Center(child: Text('No se encontraron cobros'))
            : Column(
          children: [
            construirResumen(),
            construirBuscadorYAcciones(),
            if (hayFiltrosActivos)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros activos',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: limpiarFiltros,
                      icon: const Icon(Icons.close),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: cobrosFiltrados.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay cobros que coincidan con los filtros',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: cargarCobros,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.only(bottom: 16, top: 4),
                  itemCount: cobrosFiltrados.length,
                  itemBuilder: (context, index) {
                    return construirCardCobro(
                      cobrosFiltrados[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}