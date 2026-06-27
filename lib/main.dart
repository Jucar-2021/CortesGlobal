import 'administrador/homeAdmin.dart';
import 'administrador/adminUser/altaAdmin.dart';
import 'api/consumoPHP.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'calendarios/cal_ingresoCortes.dart';
import 'api/user/user_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OperaGas - Gestión de Cortes",
      theme: base,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('es'),
        Locale('en', 'US'),
      ],
      home: const Cortes(),
      initialRoute: '/login',
      routes: {'/login': (_) => const Cortes()},
      onGenerateRoute: (settings) {
        if (settings.name == '/captura') {
          final args = settings.arguments as Map<String, dynamic>?;

          final usuario = args?['usuario'] as String? ?? '';
          final idUsuario = args?['idUsuario'] as int? ?? 0;
          final nombre = args?['nombre'] as String? ?? '';
          final apellidoPaterno = args?['apellidoPaterno'] as String? ?? '';
          final apellidoMaterno = args?['apellidoMaterno'] as String? ?? '';

          return MaterialPageRoute(
            builder: (_) => Captura(
              usuario: usuario,
              idUsuario: idUsuario,
              nombre: nombre,
              apellidoPaterno: apellidoPaterno,
              apellidoMaterno: apellidoMaterno,
            ),
          );
        }
        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text("Ruta no encontrada"))),
      ),
    );
  }
}

class Cortes extends StatefulWidget {
  const Cortes({super.key});

  @override
  State<Cortes> createState() => _CortesState();
}

class _CortesState extends State<Cortes> {
  final TextEditingController usuario = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController claveAcceso = TextEditingController();
  final TextEditingController codigoEmpresa = TextEditingController();
  final TextEditingController codigoEmpresaAdmin = TextEditingController();

  bool _loginLoading = false;
  bool _biometriaDisponible = false;
  bool _credencialesGuardadas = false;

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const _keyEmpresa = 'login_empresa';
  static const _keyUsuario = 'login_usuario';
  static const _keyPassword = 'login_password';

  // ===================== API & USERAPI =====================
  final ApiService apiService = ApiService();
  late final UserApi userApi = UserApi(apiService);

  @override
  void initState() {
    super.initState();
    _inicializarLogin();
    apiService
        .postJson('ping.php', {})
        .then((data) => debugPrint('Ping: $data'))
        .catchError((e) => debugPrint('Error ping: $e'));
  }

  Future<void> _inicializarLogin() async {
    // Cargar credenciales guardadas
    final empresaGuardada = await _secureStorage.read(key: _keyEmpresa);
    final usuarioGuardado = await _secureStorage.read(key: _keyUsuario);
    final passwordGuardado = await _secureStorage.read(key: _keyPassword);

    final tieneCredenciales = empresaGuardada != null &&
        usuarioGuardado != null &&
        passwordGuardado != null;

    // Verificar soporte biométrico
    bool soportaBiometria = false;
    try {
      soportaBiometria = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (soportaBiometria) {
        final biometricos = await _localAuth.getAvailableBiometrics();
        soportaBiometria = biometricos.isNotEmpty;
      }
    } catch (_) {
      soportaBiometria = false;
    }

    if (!mounted) return;

    // Pre-rellenar campos con datos guardados
    if (empresaGuardada != null) codigoEmpresa.text = empresaGuardada;
    if (usuarioGuardado != null) usuario.text = usuarioGuardado;

    setState(() {
      _biometriaDisponible = soportaBiometria;
      _credencialesGuardadas = tieneCredenciales;
    });
  }

  Future<void> _guardarCredenciales(
      String empresa, String usuarioVal, String password) async {
    await _secureStorage.write(key: _keyEmpresa, value: empresa);
    await _secureStorage.write(key: _keyUsuario, value: usuarioVal);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  Future<void> _autenticarConHuella() async {
    try {
      final autenticado = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella dactilar para iniciar sesión',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!autenticado || !mounted) return;

      // Cargar contraseña guardada y proceder con login
      final passwordGuardado = await _secureStorage.read(key: _keyPassword);
      if (passwordGuardado == null) return;

      pass.text = passwordGuardado;
      await _iniciarSesion(guardandoCredenciales: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de autenticación biométrica: $e')),
      );
    }
  }

  @override
  void dispose() {
    usuario.dispose();
    pass.dispose();
    claveAcceso.dispose();
    codigoEmpresa.dispose();
    codigoEmpresaAdmin.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion({bool guardandoCredenciales = true}) async {
    if (_loginLoading) return;

    final user = usuario.text.trim();
    final pwd = pass.text.trim();
    final empresa = codigoEmpresa.text.trim();

    if (empresa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de empresa')),
      );
      return;
    }

    setState(() => _loginLoading = true);

    final datosUsuario = await userApi
        .validarUsuario(user, pwd, empresa)
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión: $e')),
          );
          return null;
        });

    if (!mounted) return;
    setState(() => _loginLoading = false);

    if (datosUsuario != null) {
      // Guardar credenciales para futuros inicios
      if (guardandoCredenciales) {
        await _guardarCredenciales(empresa, user, pwd);
        if (mounted) {
          setState(() => _credencialesGuardadas = true);
        }
      }

      final idUsuario = datosUsuario['idUsuario'];
      final usuarioLogin = datosUsuario['usuario'];
      final nombre = datosUsuario['nombre'];
      final apellidoPaterno = datosUsuario['apellidoPaterno'];
      final apellidoMaterno = datosUsuario['apellidoMaterno'];

      Navigator.pushReplacementNamed(
        context,
        '/captura',
        arguments: {
          'usuario': usuarioLogin,
          'idUsuario': idUsuario,
          'nombre': '$nombre',
          'apellidoPaterno': '$apellidoPaterno',
          'apellidoMaterno': '$apellidoMaterno',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
    }
  }

  Future<void> _abrirAdmin() async {
    final accesoConcedido = await mostrarDialogoClaveAcceso(context);

    if (!mounted) return;

    codigoEmpresaAdmin.clear();
    claveAcceso.clear();

    if (accesoConcedido) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeAdmin()),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Acceso concedido.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso denegado. Verifique empresa y clave.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mostrarBotonHuella = _biometriaDisponible && _credencialesGuardadas;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary.withOpacity(0.15), cs.surface, cs.surface],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: cs.primary.withOpacity(0.15),
                              child: Icon(
                                Icons.local_gas_station,
                                color: cs.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cortes Despachador",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Inicia sesión para continuar",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Card Login
                        Card(
                          elevation: 8,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Inicio de sesión",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: codigoEmpresa,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    labelText: "Código de Empresa",
                                    hintText: "Ejemplo: 1234",
                                    prefixIcon: const Icon(Icons.business),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: usuario,
                                  textInputAction: TextInputAction.next,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    labelText: "Usuario",
                                    hintText: "Ingrese su usuario",
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: pass,
                                  maxLength: 10,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    labelText: "Contraseña",
                                    hintText: mostrarBotonHuella
                                        ? "O usa tu huella dactilar"
                                        : "Ingrese su contraseña",
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onSubmitted: (_) => _iniciarSesion(),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: _loginLoading
                                        ? null
                                        : _iniciarSesion,
                                    icon: _loginLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    label: Text(
                                      _loginLoading
                                          ? "Validando..."
                                          : "Iniciar sesión",
                                    ),
                                  ),
                                ),

                                // Botón huella dactilar (solo si el equipo lo soporta y hay credenciales)
                                if (mostrarBotonHuella) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _loginLoading
                                          ? null
                                          : _autenticarConHuella,
                                      icon: const Icon(Icons.fingerprint),
                                      label: const Text("Acceder con huella"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.primary,
                                        side: BorderSide(color: cs.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: _abrirAdmin,
                                    icon: const Icon(
                                      Icons.admin_panel_settings,
                                    ),
                                    label: const Text(
                                      "Opciones de administrador",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            "© ${DateTime.now().year} • Desarrollado por JCGL",
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> mostrarDialogoClaveAcceso(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clave de Acceso Requerida'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                controller: codigoEmpresaAdmin,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Código Empresa',
                  prefixIcon: Icon(Icons.business),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                keyboardType: TextInputType.number,
                controller: claveAcceso,
                textInputAction: TextInputAction.done,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ingrese la clave de acceso',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () async {
                final empresa = codigoEmpresaAdmin.text.trim();
                final clave = int.tryParse(claveAcceso.text.trim()) ?? 0;

                if (empresa.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa el código de empresa'),
                    ),
                  );
                  return;
                }

                if (clave <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa una clave válida')),
                  );
                  return;
                }

                try {
                  debugPrint('Intentando validar admin...');
                  final datosAdmin = await userApi.validarAdmin(clave, empresa);

                  if (!context.mounted) return;

                  if (datosAdmin != null && datosAdmin['ok'] == true) {
                    final esClaveMatestra =
                        datosAdmin['es_clave_maestra'] ?? false;

                    debugPrint(
                      'Login exitoso. Es clave maestra: $esClaveMatestra',
                    );

                    Navigator.of(context).pop(true);

                    await Future.delayed(const Duration(milliseconds: 300));
                    if (!context.mounted) return;

                    if (esClaveMatestra) {
                      debugPrint('Navegando a AltaAdmin (modo clave maestra)');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AltaAdmin()),
                      );
                    } else {
                      debugPrint('Navegando a HomeAdmin (admin registrado)');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeAdmin()),
                      );
                    }
                  } else {
                    Navigator.of(context).pop(false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clave de administrador incorrecta'),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Excepción en validarAdmin: $e');
                  if (!context.mounted) return;
                  Navigator.of(context).pop(false);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}
