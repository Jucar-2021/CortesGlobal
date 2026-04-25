import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/consumoPHP.dart';
import '../api/client/clientes_api.dart';

class _ClientesItem {
  final int? idCliente; // null = aún no existe en BD
  final TextEditingController controller;
  final FocusNode focusNode;

  _ClientesItem({
    required this.idCliente,
    required this.controller,
    required this.focusNode,
  });
}

class ClientesCapturaPage extends StatefulWidget {
  final int idUsuario;
  final int idCliente;
  final String razonSocial;
  final String fecha; // "yyyy/MM/dd"
  final String producto;

  const ClientesCapturaPage({
    super.key,
    required this.idUsuario,
    required this.idCliente,
    required this.razonSocial,
    required this.fecha,
    required this.producto,
  });

  @override
  State<ClientesCapturaPage> createState() => _ClientesCapturaPageState();
}

class _ClientesCapturaPageState extends State<ClientesCapturaPage> {
  final List<_ClientesItem> _items = [];
  double _total = 0;
  bool _cargando = true;
  String? _errorCarga;

  bool _yaExistia = false; // controla "Guardar" vs "Actualizar"
  bool _guardando = false; // overlay "Registrando vouchers..."

  late final ApiService apiService;
  late final ClientesApi clientesApi;

  late int idUsuario = widget.idUsuario;
  late int idCliente = widget.idCliente;
  late String razonSocial = widget.razonSocial;
  late String fecha = widget.fecha; // "yyyy/MM/dd"
  late String producto = widget.producto;

  @override
  void initState() {
    super.initState();
    _items.add(_nuevoItemVacio());
    apiService = ApiService();
    clientesApi = ClientesApi(apiService);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.controller.dispose();
      it.focusNode.dispose();
    }
    super.dispose();
  }

  _ClientesItem _nuevoItemVacio() {
    return _ClientesItem(
      idCliente: null,
      controller: TextEditingController(),
      focusNode: FocusNode(),
    );
  }

  _ClientesItem _itemDesdeBD(
      {required int idCliente, required double importe}) {
    return _ClientesItem(
      idCliente: idCliente,
      controller: TextEditingController(text: importe.toStringAsFixed(2)),
      focusNode: FocusNode(),
    );
  }

  // ===================== CARGA INICIAL =====================
  Future<void> _cargarDatosIniciales() async {
    try {
      final rows = await clientesApi.getClienteconsumo(
        idCliente: idCliente,
        idUsuario: idUsuario,
        fecha: fecha,
        producto:
            producto, // nuevo campo para compatibilidad con tu función actual
      );

      if (!mounted) return;

      // limpiar items actuales
      for (final it in _items) {
        it.controller.dispose();
        it.focusNode.dispose();
      }
      _items.clear();

      if (rows.isNotEmpty) {
        _yaExistia = true;

        for (final r in rows) {
          final idConsumo = r['idConsumo'] as int;
          final importe = (r['importe'] as num).toDouble();
          _items.add(_itemDesdeBD(idCliente: idConsumo, importe: importe));
        }
      } else {
        _yaExistia = false;
      }

      // deja un campo extra vacío al final
      _items.add(_nuevoItemVacio());

      _recalcularTotal();
    } catch (e) {
      if (!mounted) return;
      _errorCarga = 'Error al cargar clientes: $e';
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ===================== TOTALES =====================
  void _recalcularTotal() {
    double suma = 0;
    for (final it in _items) {
      final v = double.tryParse(it.controller.text) ?? 0;
      suma += v;
    }
    if (mounted) setState(() => _total = suma);
  }

  // ===================== NEXT / DONE =====================
  void _onSubmittedCampo(int index) {
    // si es el último campo y ya tiene texto, crea uno nuevo y enfoca
    if (index == _items.length - 1 &&
        _items[index].controller.text.isNotEmpty) {
      setState(() => _items.add(_nuevoItemVacio()));

      Future.microtask(() {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_items[index + 1].focusNode);
      });
      return;
    }

    // si hay siguiente, enfócalo
    if (index + 1 < _items.length) {
      FocusScope.of(context).requestFocus(_items[index + 1].focusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _onChangedCampo(int index, String _) {
    _recalcularTotal();

    // si escriben en el último y ya tiene texto, agrega otro vacío
    if (index == _items.length - 1 &&
        _items[index].controller.text.isNotEmpty) {
      setState(() => _items.add(_nuevoItemVacio()));
    }
  }

  List<double> _obtenerImportesValidos() {
    final List<double> importes = [];
    for (final it in _items) {
      final v = double.tryParse(it.controller.text);
      if (v != null && v > 0) importes.add(v);
    }
    return importes;
  }

  // ===================== GUARDAR / ACTUALIZAR =====================
  Future<void> _guardarNuevo(List<double> importes) async {
    await clientesApi.registrarClientes(
      idUsuario: idUsuario,
      idCliente: idCliente,
      razonSocial: razonSocial,
      fecha: fecha,
      importes: importes,
      producto:
          producto, // nuevo campo para compatibilidad con tu función actual
    );
  }

  Future<void> _actualizar(List<double> importes) async {
    await clientesApi.actualizarClientes(
      idUsuario: idUsuario,
      idCliente: idCliente,
      razonSocial: razonSocial,
      fecha: fecha,
      importes: importes,
      producto: widget
          .producto, // nuevo campo para compatibilidad con tu función actual
    );
  }

  Future<void> _guardar() async {
    // Si ya está guardando, no hacer nada
    if (_guardando) return;

    // Cierra teclado
    FocusScope.of(context).unfocus();

    final importes = _obtenerImportesValidos();

    // ✅ NUEVO: si no hay importes, regresar sin pedir nada
    if (importes.isEmpty) {
      Navigator.pop<double>(context, _total);
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _guardando = true);

      if (_yaExistia) {
        await _actualizar(importes);
      } else {
        await _guardarNuevo(importes);
      }

      if (!mounted) return;
      setState(() => _guardando = false);

      Navigator.pop<double>(context, _total);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al registrar importes de $razonSocial: $e')),
      );
    }
  }

  // ===================== ELIMINAR POR FILA =====================
  Future<void> _eliminarRegistro(int index) async {
    if (_guardando) return; // bloquea mientras guarda

    final item = _items[index];

    // No eliminar el último campo vacío
    final esUltimoYVacio =
        index == _items.length - 1 && item.controller.text.isEmpty;
    if (esUltimoYVacio) return;

    // Si no existe en BD aún, solo quítalo de la lista
    if (item.idCliente == null) {
      setState(() {
        item.controller.dispose();
        item.focusNode.dispose();
        _items.removeAt(index);
        if (_items.isEmpty) _items.add(_nuevoItemVacio());
      });
      _recalcularTotal();
      return;
    }

    try {
      await clientesApi.eliminarImporteCliente(item.idCliente!);

      if (!mounted) return;

      setState(() {
        item.controller.dispose();
        item.focusNode.dispose();
        _items.removeAt(index);
        if (_items.isEmpty) _items.add(_nuevoItemVacio());
      });

      // si ya no hay registros reales en BD, cambia a Guardar
      final quedanReales = _items.any((x) => x.idCliente != null);
      _yaExistia = quedanReales;

      _recalcularTotal();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  String _fmt(double valor) {
    return _currencyFormat.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorCarga != null) {
      final mensaje = _errorCarga!;
      _errorCarga = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              razonSocial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          children: [
                            Text(
                              'Importes de cargas: $razonSocial.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];

                                  final esUltimo = index == _items.length - 1;
                                  final action = esUltimo
                                      ? TextInputAction.done
                                      : TextInputAction.next;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: item.controller,
                                            focusNode: item.focusNode,
                                            enabled: !_guardando,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            textInputAction: action,
                                            decoration: InputDecoration(
                                              labelText: 'Baucher ${index + 1}',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14,
                                              ),
                                            ),
                                            onChanged: (value) =>
                                                _onChangedCampo(index, value),
                                            onSubmitted: (_) =>
                                                _onSubmittedCampo(index),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Focus(
                                            canRequestFocus: false,
                                            skipTraversal: true,
                                            child: IconButton(
                                              tooltip: 'Eliminar',
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: _guardando
                                                  ? null
                                                  : () =>
                                                      _eliminarRegistro(index),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          12,
                          10,
                          12,
                          MediaQuery.of(context).viewPadding.bottom > 0
                              ? 12
                              : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 192, 234, 255),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 2, 92, 219)
                                      .withOpacity(0.20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _fmt(_total),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 2, 92, 219),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: Text(
                                  _yaExistia
                                      ? 'Actualizar importes'
                                      : 'Guardar clientes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _guardando ? null : _guardar,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                                'Registrando clientes...',
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
    );
  }
}
