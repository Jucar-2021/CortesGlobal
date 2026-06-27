import 'package:flutter/material.dart';
import '../../api/user/admin_api.dart';
import '../../api/consumoPHP.dart';

class AltaAdmin extends StatefulWidget {
  const AltaAdmin({super.key});

  @override
  State<AltaAdmin> createState() => _AltaAdminState();
}

class _AltaAdminState extends State<AltaAdmin> {
  final ApiService apiService = ApiService();
  late AdminApi adminApi;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _claveController = TextEditingController();
  final _claveConfirmController = TextEditingController();

  bool _guardando = false;
  bool _claveVisible = false;
  bool _claveConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    adminApi = AdminApi(apiService);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _claveController.dispose();
    _claveConfirmController.dispose();
    super.dispose();
  }

  Future<void> _registrarAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_claveController.text != _claveConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las claves no coinciden')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    try {
      final clave = int.tryParse(_claveController.text) ?? 0;

      await adminApi.altaAdmin(
        nombre: _nombreController.text.trim(),
        apellidoPaterno: _apellidoPaternoController.text.trim(),
        apellidoMaterno: _apellidoMaternoController.text.trim(),
        clave: clave,
      );

      if (!mounted) return;
      setState(() => _guardando = false);

      _limpiarFormulario();
      _showExitoDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _claveController.clear();
    _claveConfirmController.clear();
  }

  void _showExitoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Éxito'),
        content: const Text('Administrador registrado exitosamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _overlayGuardando() {
    return Positioned.fill(
      child: Container(
        color: const Color.fromARGB(200, 82, 80, 80),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'Registrando administrador...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text('Registrar Administrador'),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildSectionTitle('Datos Personales'),
                  const SizedBox(height: 12),
                  _buildTextFormField(
                    controller: _nombreController,
                    label: 'Nombre',
                    hint: 'Ej: Juan',
                    icon: Icons.person,
                    enabled: !_guardando,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextFormField(
                    controller: _apellidoPaternoController,
                    label: 'Apellido Paterno',
                    hint: 'Ej: Pérez',
                    icon: Icons.person_outline,
                    enabled: !_guardando,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido paterno es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextFormField(
                    controller: _apellidoMaternoController,
                    label: 'Apellido Materno',
                    hint: 'Ej: García',
                    icon: Icons.person_outline,
                    enabled: !_guardando,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido materno es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Seguridad'),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _claveController,
                    label: 'Clave',
                    visible: _claveVisible,
                    onVisibilityToggle: () {
                      setState(() => _claveVisible = !_claveVisible);
                    },
                    enabled: !_guardando,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La clave es requerida';
                      }
                      if (value.length < 4) {
                        return 'La clave debe tener al menos 4 dígitos';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'La clave solo debe contener números';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _claveConfirmController,
                    label: 'Confirmar Clave',
                    visible: _claveConfirmVisible,
                    onVisibilityToggle: () {
                      setState(() => _claveConfirmVisible = !_claveConfirmVisible);
                    },
                    enabled: !_guardando,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debes confirmar la clave';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _registrarAdmin,
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Registrar Administrador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_guardando) _overlayGuardando(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0D47A1),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.25)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onVisibilityToggle,
    required bool enabled,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: !visible,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingresa tu clave numérica',
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF1565C0)),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF1565C0),
          ),
          onPressed: enabled ? onVisibilityToggle : null,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.25)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      validator: validator,
    );
  }
}
