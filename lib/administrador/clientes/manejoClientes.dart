import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/client/manejoCli_api.dart';
import '../../api/consumoPHP.dart';

class Manejoclientes extends StatefulWidget {
  const Manejoclientes({super.key});

  @override
  State<Manejoclientes> createState() => _ManejoclientesState();
}

class _ManejoclientesState extends State<Manejoclientes> {
  final ApiService apiCli = ApiService();
  late ClienteAdminApi clienteApi;

  final TextEditingController _nuevoClienteController = TextEditingController();
  final Map<int, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    clienteApi = ClienteAdminApi(apiCli);
    _fetchCliente();
  }

  @override
  void dispose() {
    _nuevoClienteController.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  final upperCaseFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  });

  Future<void> _fetchCliente() async {
    try {
      setState(() => _cargando = true);

      final clientes = await clienteApi.getClientes();

      if (!mounted) return;

      setState(() {
        _clientes = List<Map<String, dynamic>>.from(clientes);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener clientes: $e')));
    }
  }

  Future<void> _registrarCliente(String razonSocial) async {
    final nombre = razonSocial.trim().toUpperCase();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la razón social del cliente')),
      );
      return;
    }

    try {
      await clienteApi.registrarCliente(razonSocial: nombre);
      _nuevoClienteController.clear();
      await _fetchCliente();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar cliente: $e')));
    }
  }

  Future<void> _actualizarCliente(int IdCliente, String razonSocial) async {
    final nombre = razonSocial.trim().toUpperCase();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del cliente no puede ir vacío'),
        ),
      );
      return;
    }

    final index = _clientes.indexWhere(
      (b) => int.parse(b['IdCliente'].toString()) == IdCliente,
    );

    if (index == -1) return;

    final nombreAnterior = _clientes[index]['razonSocial'];

    setState(() {
      _clientes[index]['razonSocial'] = nombre;
    });

    try {
      await clienteApi.actualizarCliente(
        IdCliente: IdCliente,
        razonSocial: nombre,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente actualizado correctamente')),
      );
    } catch (e) {
      setState(() {
        _clientes[index]['razonSocial'] = nombreAnterior;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar cliente: $e')),
      );
    }
  }

  Future<void> _cambiarEstadoCliente(int IdCliente, bool activo) async {
    final int nuevoEstado = activo ? 1 : 0;

    final index = _clientes.indexWhere(
      (b) => int.parse(b['IdCliente'].toString()) == IdCliente,
    );

    if (index == -1) return;

    final estadoAnterior = _clientes[index]['estado'];

    setState(() {
      _clientes[index]['estado'] = nuevoEstado;
    });

    try {
      await clienteApi.cambiarEstadoCliente(
        IdCliente: IdCliente,
        estado: nuevoEstado,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _clientes[index]['estado'] = estadoAnterior;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado del cliente: $e')),
      );
    }
  }

  Future<void> _eliminarCliente(int IdCliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text('¿Seguro que deseas eliminar este cliente?'),
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

    final index = _clientes.indexWhere(
      (b) => int.parse(b['IdCliente'].toString()) == IdCliente,
    );

    if (index == -1) return;

    final clienteEliminado = Map<String, dynamic>.from(_clientes[index]);

    setState(() {
      _clientes.removeAt(index);
    });

    try {
      await clienteApi.eliminarCliente(IdCliente: IdCliente);
      _controllers.remove(IdCliente)?.dispose();
    } catch (e) {
      setState(() {
        _clientes.insert(index, clienteEliminado);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar cliente: $e')));
    }
  }

  int _obtenerEstado(Map<String, dynamic> cliente) {
    final estadoRaw =
        cliente['estado'] ?? cliente['Estado'] ?? cliente['activo'] ?? 0;

    return int.tryParse(estadoRaw.toString()) ?? 0;
  }

  Widget _buildClientesCard(Map<String, dynamic> cliente) {
    final int IdCliente = int.parse(cliente['IdCliente'].toString());
    final String nombreCliente = cliente['razonSocial'].toString();

    final int estado = _obtenerEstado(cliente);
    final bool activo = estado == 1;

    final controller = _controllers.putIfAbsent(
      IdCliente,
      () => TextEditingController(text: nombreCliente),
    );

    if (controller.text != nombreCliente) {
      controller.text = nombreCliente;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: activo
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: activo ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombreCliente,
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
                    await _cambiarEstadoCliente(IdCliente, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              inputFormatters: [upperCaseFormatter],
              decoration: InputDecoration(
                labelText: 'Nombre del Cliente',
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
                      _actualizarCliente(IdCliente, controller.text);
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
                    onPressed: () => _eliminarCliente(IdCliente),
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
                activo
                    ? 'Cliente activo para operaciones'
                    : 'Cliente desactivado',
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

  void _mostrarDialogoNuevoCliente() {
    _nuevoClienteController.clear();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Registrar nuevo cliente'),
          content: TextFormField(
            controller: _nuevoClienteController,
            inputFormatters: [upperCaseFormatter],
            decoration: const InputDecoration(
              labelText: 'Nombre del cliente',
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
                await _registrarCliente(_nuevoClienteController.text);

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
        title: const Text('Manejo de Clientes'),
        centerTitle: true,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
          ? const Center(
              child: Text(
                'No hay clientes registrados',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                return _buildClientesCard(_clientes[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoCliente,
        backgroundColor: const Color(0xFF005498),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar cliente'),
      ),
    );
  }
}
