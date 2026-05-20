import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/consumoPHP.dart';
import '../../api/bancos/bancos_api.dart';

class BancosManejo extends StatefulWidget {
  const BancosManejo({super.key});

  @override
  State<BancosManejo> createState() => _BancosManejoState();
}

class _BancosManejoState extends State<BancosManejo> {
  final ApiService apiService = ApiService();
  late final BancosApi bancosApi;

  final TextEditingController _nuevoBancoController = TextEditingController();
  final Map<int, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> _bancos = [];
  bool _cargando = true;

  final upperCaseFormatter = TextInputFormatter.withFunction((
      oldValue,
      newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  });

  @override
  void initState() {
    super.initState();
    bancosApi = BancosApi(apiService);
    _fetchBancos();
  }

  @override
  void dispose() {
    _nuevoBancoController.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _fetchBancos() async {
    try {
      setState(() => _cargando = true);

      final bancos = await bancosApi.getBancos();

      if (!mounted) return;

      setState(() {
        _bancos = List<Map<String, dynamic>>.from(bancos);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener bancos: $e')),
      );
    }
  }

  Future<void> _registrarBanco(String nombreBanco) async {
    final nombre = nombreBanco.trim().toUpperCase();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del banco')),
      );
      return;
    }

    try {
      await bancosApi.registrarBanco(nombreBanco: nombre);
      _nuevoBancoController.clear();
      await _fetchBancos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar banco: $e')),
      );
    }
  }

  Future<void> _actualizarBanco(int idBanco, String nombreBanco) async {
    final nombre = nombreBanco.trim().toUpperCase();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del banco no puede ir vacío')),
      );
      return;
    }

    final index = _bancos.indexWhere(
          (b) => int.parse(b['idBanco'].toString()) == idBanco,
    );

    if (index == -1) return;

    final nombreAnterior = _bancos[index]['nombreBanco'];

    setState(() {
      _bancos[index]['nombreBanco'] = nombre;
    });

    try {
      await bancosApi.actualizarBanco(
        idBanco: idBanco,
        nombreBanco: nombre,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banco actualizado correctamente')),
      );
    } catch (e) {
      setState(() {
        _bancos[index]['nombreBanco'] = nombreAnterior;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar banco: $e')),
      );
    }
  }

  Future<void> _cambiarEstadoBanco(int idBanco, bool activo) async {
    final int nuevoEstado = activo ? 1 : 0;

    final index = _bancos.indexWhere(
          (b) => int.parse(b['idBanco'].toString()) == idBanco,
    );

    if (index == -1) return;

    final estadoAnterior = _bancos[index]['estado'];

    setState(() {
      _bancos[index]['estado'] = nuevoEstado;
    });

    try {
      await bancosApi.cambiarEstadoBanco(
        idBanco: idBanco,
        estado: nuevoEstado,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _bancos[index]['estado'] = estadoAnterior;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado del banco: $e')),
      );
    }
  }

  Future<void> _eliminarBanco(int idBanco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar banco'),
        content: const Text('¿Seguro que deseas eliminar este banco?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final index = _bancos.indexWhere(
          (b) => int.parse(b['idBanco'].toString()) == idBanco,
    );

    if (index == -1) return;

    final bancoEliminado = Map<String, dynamic>.from(_bancos[index]);

    setState(() {
      _bancos.removeAt(index);
    });

    try {
      await bancosApi.eliminarBanco(idBanco: idBanco);
      _controllers.remove(idBanco)?.dispose();
    } catch (e) {
      setState(() {
        _bancos.insert(index, bancoEliminado);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar banco: $e')),
      );
    }
  }

  int _obtenerEstado(Map<String, dynamic> banco) {
    final estadoRaw =
        banco['estado'] ?? banco['Estado'] ?? banco['activo'] ?? 0;

    return int.tryParse(estadoRaw.toString()) ?? 0;
  }

  Widget _buildBancoCard(Map<String, dynamic> banco) {
    final int idBanco = int.parse(banco['idBanco'].toString());
    final String nombreBanco = banco['nombreBanco'].toString();

    final int estado = _obtenerEstado(banco);
    final bool activo = estado == 1;

    final controller = _controllers.putIfAbsent(
      idBanco,
          () => TextEditingController(text: nombreBanco),
    );

    if (controller.text != nombreBanco) {
      controller.text = nombreBanco;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                  activo ? Colors.green.shade100 : Colors.grey.shade300,
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: activo ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombreBanco,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: activo,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (value) async {
                    await _cambiarEstadoBanco(idBanco, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              inputFormatters: [upperCaseFormatter],
              decoration: InputDecoration(
                labelText: 'Nombre del banco',
                prefixIcon: const Icon(Icons.edit_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _actualizarBanco(idBanco, controller.text);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Actualizar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _eliminarBanco(idBanco),
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activo ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activo ? 'Banco activo para operaciones' : 'Banco desactivado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: activo ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoBanco() {
    _nuevoBancoController.clear();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Registrar nuevo banco'),
          content: TextFormField(
            controller: _nuevoBancoController,
            inputFormatters: [upperCaseFormatter],
            decoration: const InputDecoration(
              labelText: 'Nombre del banco',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await _registrarBanco(_nuevoBancoController.text);

                if (!mounted) return;
                Navigator.pop(context);
              },
              label: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Manejo de Bancos'),
        centerTitle: true,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _bancos.isEmpty
          ? const Center(
        child: Text(
          'No hay bancos registrados',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bancos.length,
        itemBuilder: (context, index) {
          return _buildBancoCard(_bancos[index]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoBanco,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar banco'),
      ),
    );
  }
}