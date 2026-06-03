import 'package:flutter/services.dart';
import '../../api/consumoPHP.dart';
import 'package:flutter/material.dart';
import '../../api/user/user_api.dart';
import '../../administrador/authServise/authServise.dart';

class Registro extends StatelessWidget {
  const Registro({super.key});

  @override
  Widget build(BuildContext context) {
    return const NuevoUsuario();
  }
}

class NuevoUsuario extends StatefulWidget {
  const NuevoUsuario({super.key});

  @override
  State<NuevoUsuario> createState() => _NuevoUsuarioState();
}

class _NuevoUsuarioState extends State<NuevoUsuario> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usuarios = TextEditingController();
  final TextEditingController nombre = TextEditingController();
  final TextEditingController apellidoPaterno = TextEditingController();
  final TextEditingController apellidoMaterno = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController pass2 = TextEditingController();

  bool _verPass = false;
  bool _verPass2 = false;
  bool _registrando = false;

  final ApiService apiService = ApiService();
  late final UserApi userApi;

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
    usuarios.text = "";
    nombre.text = "";
    apellidoPaterno.text = "";
    apellidoMaterno.text = "";
    pass.text = "";
    pass2.text = "";
    userApi = UserApi(apiService);
  }

  @override
  void dispose() {
    usuarios.dispose();
    pass.dispose();
    pass2.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_registrando) return;

    // valida form
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _registrando = true);

    try {
      final success = await userApi.registrarUsuario(
        usuarios.text.trim(),
        pass.text.trim(),
        nombre.text.trim(),
        apellidoPaterno.text.trim(),
        apellidoMaterno.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado con éxito')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el usuario. Intente nuevamente.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _registrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Registro de Usuario",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService.cerrarSesion();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary.withOpacity(0.12), cs.surface, cs.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 10,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: cs.primary.withOpacity(0.15),
                                child: Icon(
                                  Icons.person_add_alt_1,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Nuevo usuario",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Crea una cuenta para acceder al sistema.",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // NOMBRE
                          TextFormField(
                            controller: nombre,
                            maxLength: 50,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [upperCaseFormatter],
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Nombre",
                              hintText: "Ej: Juan",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) {
                                return 'Ingresa un nombre';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // APELLIDO PATERNO
                          TextFormField(
                            controller: apellidoPaterno,
                            maxLength: 50,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [upperCaseFormatter],
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Apellido Paterno",
                              hintText: "Ej: Alvarez",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) {
                                return 'Ingresa un apellido paterno';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // APELLIDO MATERNO
                          TextFormField(
                            controller: apellidoMaterno,
                            maxLength: 50,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [upperCaseFormatter],
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Apellido Materno",
                              hintText: "Ej: García",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) {
                                return 'Ingresa un apellido materno';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // USUARIO
                          TextFormField(
                            controller: usuarios,
                            maxLength: 10,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Usuario",
                              hintText: "Ej: juanito70",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) {
                                return 'Ingresa un usuario';
                              }
                              if (value.length < 5) {
                                return 'Mínimo 5 caracteres';
                              }
                              // opcional: solo letras/números
                              final ok = RegExp(
                                r'^[a-zA-Z0-9_]+$',
                              ).hasMatch(value);
                              if (!ok) return 'Solo letras, números o _';
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // CONTRASEÑA
                          TextFormField(
                            controller: pass,
                            maxLength: 10,
                            obscureText: !_verPass,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Contraseña",
                              hintText: "Crea una contraseña",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                tooltip: _verPass ? 'Ocultar' : 'Mostrar',
                                icon: Icon(
                                  _verPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _verPass = !_verPass),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty)
                                return 'Ingresa una contraseña';
                              if (value.length < 4)
                                return 'Mínimo 4 caracteres';
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // CONFIRMAR CONTRASEÑA
                          TextFormField(
                            controller: pass2,
                            maxLength: 10,
                            obscureText: !_verPass2,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Confirmar contraseña",
                              hintText: "Repite la contraseña",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _verPass2 ? 'Ocultar' : 'Mostrar',
                                icon: Icon(
                                  _verPass2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _verPass2 = !_verPass2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty)
                                return 'Confirma la contraseña';
                              if (value != pass.text.trim()) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _registrar(),
                          ),

                          const SizedBox(height: 16),

                          // BOTÓN REGISTRAR
                          SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _registrando ? null : _registrar,
                              icon: _registrando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                _registrando ? "Registrando..." : "Registrar",
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // CANCELAR / VOLVER
                          SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _registrando
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Volver"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
