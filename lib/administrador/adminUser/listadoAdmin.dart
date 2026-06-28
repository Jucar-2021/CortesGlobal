import 'package:flutter/material.dart';
import '../../api/user/admin_api.dart';
import '../../api/consumoPHP.dart';
import 'altaAdmin.dart';

class ListaAdmin extends StatefulWidget {
  const ListaAdmin({super.key});

  @override
  State<ListaAdmin> createState() => _ListaAdminState();
}

class _ListaAdminState extends State<ListaAdmin> {
  final ApiService _apiService = ApiService();
  late final AdminApi _adminApi = AdminApi(_apiService);

  late Future<List<Map<String, dynamic>>> _futureAdmins;

  @override
  void initState() {
    super.initState();
    _cargarAdmins();
  }

  void _cargarAdmins() {
    _futureAdmins = _adminApi.listarAdmins();
  }

  void _recargar() => setState(() => _cargarAdmins());

  Future<void> _toggleEstado(Map<String, dynamic> admin) async {
    final idAdmin = admin['idAdministrador'] as int;
    final estadoActual = (admin['estado'] as int?) ?? 1;
    final nuevoEstado = estadoActual == 1 ? 0 : 1;
    final nombre =
        '${admin['nombre']} ${admin['apellidoPaterno']} ${admin['apellidoMaterno']}';
    final accion = nuevoEstado == 1 ? 'activar' : 'desactivar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          nuevoEstado == 1
              ? 'Activar administrador'
              : 'Desactivar administrador',
        ),
        content: Text('¿Deseas $accion a $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: nuevoEstado == 0
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(nuevoEstado == 1 ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _adminApi.estadoAdmin(
        idAdministrador: idAdmin,
        estado: nuevoEstado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado == 1
                ? 'Administrador activado correctamente'
                : 'Administrador desactivado',
          ),
        ),
      );
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _cambiarClave(Map<String, dynamic> admin) async {
    final idAdmin = admin['idAdministrador'] as int;
    final nombre =
        '${admin['nombre']} ${admin['apellidoPaterno']} ${admin['apellidoMaterno']}';

    final claveCtrl = TextEditingController();
    final claveConfirmCtrl = TextEditingController();
    bool claveVisible = false;
    bool claveConfirmVisible = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Cambiar clave'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: claveCtrl,
                      obscureText: !claveVisible,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Nueva clave',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            claveVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setLocal(() => claveVisible = !claveVisible),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa la nueva clave';
                        if (v.length < 4) return 'Mínimo 4 dígitos';
                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                          return 'Solo números';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: claveConfirmCtrl,
                      obscureText: !claveConfirmVisible,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Confirmar clave',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            claveConfirmVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setLocal(
                            () => claveConfirmVisible = !claveConfirmVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirma la clave';
                        if (v != claveCtrl.text)
                          return 'Las claves no coinciden';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final nuevaClave = int.tryParse(claveCtrl.text) ?? 0;
                    Navigator.pop(context);
                    try {
                      await _adminApi.cambiarClave(
                        idAdministrador: idAdmin,
                        nuevaClave: nuevaClave,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clave actualizada correctamente'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text('Administradores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
            tooltip: 'Recargar',
          ),

          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AltaAdmin()),
              );
              _recargar();
            },
            tooltip: 'Agregar administrador',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAdmins,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar administradores',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 56, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'No hay administradores registrados',
                    style: TextStyle(color: cs.outline, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final admin = admins[i];
              final estado = (admin['estado'] as int?) ?? 1;
              final activo = estado == 1;
              final nombre =
                  '${admin['nombre']} ${admin['apellidoPaterno']} ${admin['apellidoMaterno']}';

              return Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: activo
                        ? Colors.green.withOpacity(0.35)
                        : Colors.red.withOpacity(0.25),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: activo
                            ? Colors.green.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.15),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: activo ? Colors.green : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: activo
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.red.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activo
                                      ? Colors.green[700]
                                      : Colors.red[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cambiar clave
                      IconButton(
                        icon: const Icon(Icons.key),
                        tooltip: 'Cambiar clave',
                        color: const Color(0xFF1565C0),
                        onPressed: () => _cambiarClave(admin),
                      ),
                      // Activar / Desactivar
                      IconButton(
                        icon: Icon(
                          activo
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_rounded,
                          size: 32,
                        ),
                        tooltip: activo ? 'Desactivar' : 'Activar',
                        color: activo ? Colors.green : Colors.grey,
                        onPressed: () => _toggleEstado(admin),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
