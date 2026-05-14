import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/consumoPHP.dart';
import '../../administrador/bancos/bancos_manejo.dart';
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

    bool isOn = true; // Estado del botón ON/OFF

  // controlador dinamico para textfield bancos listados
  final Map<int, TextEditingController> _controllers = {};

  final upperCaseFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  });

  initState() {
    super.initState();
    bancosApi = BancosApi(apiService);
    _fetchBancos();
  }

  //listar bancos
  Future<List<Map<String, dynamic>>> _fetchBancos() async {
    try {
      return await bancosApi.getBancos();
    } catch (e) {
      print('Error al obtener bancos: $e');
      return [];
    }
  }

  //registrar banco
  Future<void> _registrarBanco(String nombreBanco) async {
    try {
      await bancosApi.registrarBanco(nombreBanco: nombreBanco);
      setState(() {}); // Refrescar la lista después de registrar
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar banco: $e')));
    }
  }

  //actualizar banco
  Future<void> _actualizarBanco(int idBanco, String nombreBanco) async {
    try {
      await bancosApi.actualizarBanco(
        idBanco: idBanco,
        nombreBanco: nombreBanco,
      );
      setState(() {}); // Refrescar la lista después de actualizar
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar banco: $e')));
    }
  }

  //cambiar estado banco
  Future<void> _cambiarEstadoBanco(int idBanco, String onOff) async {
      String estado = onOff == 'ON' ? 'ACTIVO' : 'INACTIVO';
    try {
      await bancosApi.cambiarEstadoBanco(
        idBanco: idBanco,
        estado: estado,
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar estado del banco: $e')));
    }
  }

  //barra de botones para eliminar y actualizar bancos
  Widget _buildBancoActions(int idBanco) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.update, color: Colors.blue),
          onPressed: () {
            final controller = _controllers[idBanco]!;
            _actualizarBanco(idBanco, controller.text);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            try {
              await bancosApi.eliminarBanco(idBanco: idBanco);
              setState(() {}); // Refrescar la lista después de eliminar
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al eliminar banco: $e')),
              );
            }
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              isOn = !isOn; // Cambia el estado del botón
            });
            _cambiarEstadoBanco(idBanco, isOn ? 'ON' : 'OFF');
          },
          label: Text(isOn ? "ON" : "OFF"),
          icon: Icon(
            isOn ? Icons.toggle_on : Icons.toggle_off,
            color: isOn ? Colors.green : Colors.grey,
            size: 40,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manejo de Bancos")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBancos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay bancos disponibles'));
          } else {
            final bancos = snapshot.data!;
            return ListView.builder(
              itemCount: bancos.length,
              itemBuilder: (context, index) {
                final banco = bancos[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers.putIfAbsent(
                              banco['idBanco'],
                              () => TextEditingController(
                                text: banco['nombreBanco'],
                              ),
                            ),
                            inputFormatters: [upperCaseFormatter],
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Banco',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildBancoActions(banco['idBanco']),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },

        // boton para agregar banco
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String nuevoBanco = '';
              return AlertDialog(
                title: const Text('Registrar Nuevo Banco'),
                content: TextFormField(
                  controller: _nuevoBancoController,
                  inputFormatters: [upperCaseFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Banco',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _registrarBanco(_nuevoBancoController.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Registrar'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
