import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/consumoPHP.dart';
import '../api/documentos/registroDoc_api.dart';

class _DocumentoItem {
  final int? idRegistros; // null = aún no existe en BD
  final TextEditingController controller;
  final FocusNode focusNode;

  _DocumentoItem({
    required this.idRegistros,
    required this.controller,
    required this.focusNode,
  });
}

class RegistroDocumentosPage extends StatefulWidget {
  final int idUsuario;
  final String fecha; // "dd/MM/yyyy"
  final String producto; // compatibilidad con tu llamada actual
  final String banco;

  const RegistroDocumentosPage({
    super.key,
    required this.idUsuario,
    required this.fecha,
    required String user,
    required this.producto, // compatibilidad con tu llamada actual
    required this.banco,
  });

  @override
  State<RegistroDocumentosPage> createState() => _RegistroDocumentosPageState();
}

class _RegistroDocumentosPageState extends State<RegistroDocumentosPage> {
  final List<_DocumentoItem> _items = [];

  double _total = 0;
  bool _cargando = true;
  String? _errorCarga;

  bool _yaExistia = false; // controla "Guardar" vs "Actualizar"
  bool _guardando = false; // overlay "Registrando vouchers..."

  late final String banco; // ejemplo de banco, ajustar según sea necesario

  // ===================== API & USERAPI =====================
  final ApiService apiService = ApiService();
  late final BancosApi cajeroApi = BancosApi(apiService);

  @override
  void initState() {
    super.initState();
    _items.add(_nuevoItemVacio());
    banco = widget.banco;
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

  _DocumentoItem _nuevoItemVacio() {
    return _DocumentoItem(
      idRegistros: null,
      controller: TextEditingController(),
      focusNode: FocusNode(),
    );
  }

  _DocumentoItem _itemDesdeBD(
      {required int idRegistros, required double importe}) {
    return _DocumentoItem(
      idRegistros: idRegistros,
      controller: TextEditingController(text: importe.toStringAsFixed(2)),
      focusNode: FocusNode(),
    );
  }

  // ===================== CARGA INICIAL =====================
  Future<void> _cargarDatosIniciales() async {
    try {
      final rows = await cajeroApi.obtenerDatos(
        idUsuario: widget.idUsuario,
        fecha: widget.fecha,
        producto: widget.producto, // compatibilidad con tu llamada actual
        banco: banco, // ejemplo de banco, ajustar según sea necesario
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
          final idRegistros = r['id'] as int;
          final importe = (r['importe'] as num).toDouble();
          _items.add(_itemDesdeBD(idRegistros: idRegistros, importe: importe));
        }
      } else {
        _yaExistia = false;
      }

      // deja un campo extra vacío al final
      _items.add(_nuevoItemVacio());

      _recalcularTotal();
    } catch (e) {
      if (!mounted) return;
      _errorCarga = 'Error al cargar registros: $e';
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
    await cajeroApi.registrarDatos(
      idUsuario: widget.idUsuario,
      fecha: widget.fecha,
      importes: importes,
      producto: widget.producto, // compatibilidad con tu llamada actual
      banco: banco, // ejemplo de banco, ajustar según sea necesario
    );
  }

  Future<void> _actualizar(List<double> importes) async {
    await cajeroApi.actualizarDatos(
      idUsuario: widget.idUsuario,
      fecha: widget.fecha,
      importes: importes,
      producto: widget.producto, // compatibilidad con tu llamada actual
      banco: banco, // ejemplo de banco, ajustar según sea necesario
    );
  }

  Future<void> _guardar() async {
    // Si ya está guardando, no hacer nada
    if (_guardando) return;

    // Cierra teclado
    FocusScope.of(context).unfocus();

    final importes = _obtenerImportesValidos();

    // si no hay importes, regresar sin pedir nada
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
        SnackBar(content: Text('Error al registrar depósitos: $e')),
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
    if (item.idRegistros == null) {
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
      await cajeroApi.eliminarDatos(id: item.idRegistros!, banco: banco);

      if (!mounted) return;

      setState(() {
        item.controller.dispose();
        item.focusNode.dispose();
        _items.removeAt(index);
        if (_items.isEmpty) _items.add(_nuevoItemVacio());
      });

      // si ya no hay registros reales en BD, cambia a Guardar
      final quedanReales = _items.any((x) => x.idRegistros != null);
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

  _titulo(String banco) {
    switch (banco) {
      case 'Cajero':
        return Text(
          'Depósitos cajero',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 251, 113, 0)),
        );
      case 'Santander':
        return Text(
          '♨️ Bauchers Santander',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 226, 28, 14)),
        );
      case 'Mifel':
        return Text(
          'Mifel',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 10, 92, 216)),
        );
      case 'Monedero':
        return Text(
          'Efecticard',
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 251, 113, 0)),
        );
      default:
        return 'Depósitos $banco';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorCarga != null) {
      final msg = _errorCarga; // copia local

      if (msg != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        });
        _errorCarga = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _titulo(banco),
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
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Column(
                          children: [
                            const Text(
                              'Ingresa los importes de tus comprobantes.\n'
                              'Presiona "Siguiente" para pasar al siguiente campo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: item.controller,
                                            focusNode: item.focusNode,
                                            enabled: !_guardando,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            textInputAction: action,
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Comprobante ${index + 1}',
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
                                                Icons.delete_forever_outlined,
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

                    // ===== FOOTER FIJO Y SEGURO =====
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
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withOpacity(0.15),
                                    Colors.blueAccent.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.25),
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
                                      color: Colors.blue,
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
                                      ? 'Actualizar depósitos'
                                      : 'Guardar depósitos',
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

                // ================= OVERLAY "REGISTRANDO..." =================
                if (_guardando)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.25),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
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
                                'Registrando depósitos...',
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
