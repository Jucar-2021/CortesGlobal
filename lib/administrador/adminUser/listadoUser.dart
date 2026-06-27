import 'package:flutter/material.dart';
import '../adminUser/registroUser.dart';
import 'altaAdmin.dart';
import '../../api/user/adminUser_api.dart';
import '../../api/consumoPHP.dart';

class UsuariosManejo extends StatefulWidget {
  const UsuariosManejo({super.key});

  @override
  State<UsuariosManejo> createState() => _UsuariosManejoState();
}

class _UsuariosManejoState extends State<UsuariosManejo> {
  final ApiService apiService = ApiService();
  late final UserAdminApi userAdminApi;

  List<Map<String, dynamic>> usuarios = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    userAdminApi = UserAdminApi(apiService);
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    try {
      final data = await userAdminApi.getUser();

      if (!mounted) return;

      setState(() {
        usuarios = data;
      });
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar usuarios'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> _updatePassword(int idUsuario, String pass) async {
    try {
      await userAdminApi.updatePassword(idUsuario, pass);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchUsuarios();
    } catch (e) {
      debugPrint('Error al actualizar contraseña: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar contraseña'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirDialogoPassword(int idUsuario) async {
    final nuevaPass = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CambiarPasswordDialog(),
    );

    if (nuevaPass != null && nuevaPass.isNotEmpty) {
      await _updatePassword(idUsuario, nuevaPass);
    }
  }

  String _nombreCompleto(Map<String, dynamic> usuario) {
    return [
      usuario['nombre'],
      usuario['apellidoPaterno'],
      usuario['apellidoMaterno'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsuarios,
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Agregar administrador',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AltaAdmin()),
              );

              await _fetchUsuarios();
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : usuarios.isEmpty
          ? const Center(
              child: Text(
                'No hay usuarios registrados',
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchUsuarios,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  final nombre = _nombreCompleto(usuario);
                  final login = usuario['usuario'] ?? 'N/A';

                  return Card(
                    elevation: 6,
                    shadowColor: Colors.black38,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.blue.shade200, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 27,
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 21,
                            ),
                          ),
                        ),
                        title: Text(
                          nombre.isNotEmpty ? nombre : 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                size: 17,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Login: $login',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: IconButton(
                            tooltip: 'Cambiar contraseña',
                            icon: const Icon(Icons.key, color: Colors.orange),
                            onPressed: () {
                              final idUsuario = int.tryParse(
                                usuario['idUsuario'].toString(),
                              );

                              if (idUsuario != null) {
                                _abrirDialogoPassword(idUsuario);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Registro()),
          );

          await _fetchUsuarios();
        },
      ),
    );
  }
}

class CambiarPasswordDialog extends StatefulWidget {
  const CambiarPasswordDialog({super.key});

  @override
  State<CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<CambiarPasswordDialog> {
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  bool ocultarPass = true;

  @override
  void dispose() {
    passController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void _validarPassword() {
    final pass = passController.text.trim();
    final confirmar = confirmarController.text.trim();

    if (pass.isEmpty || confirmar.isEmpty) {
      _mostrarMensaje('Debes llenar ambos campos');
      return;
    }

    if (pass.length < 4) {
      _mostrarMensaje('La contraseña debe tener mínimo 4 caracteres');
      return;
    }

    if (pass != confirmar) {
      _mostrarMensaje('Las contraseñas no coinciden');
      return;
    }

    Navigator.pop(context, pass);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.key, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Cambiar contraseña'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: passController,
            obscureText: ocultarPass,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  ocultarPass ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    ocultarPass = !ocultarPass;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmarController,
            obscureText: ocultarPass,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_reset),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mínimo 4 caracteres',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Actualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          onPressed: _validarPassword,
        ),
      ],
    );
  }
}
