import '/administrador/homeAdmin.dart';
import '/api/consumoPHP.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      title: "Cortes Despachador",
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
      routes: {
        '/login': (_) => const Cortes(),
      },
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
        builder: (_) => const Scaffold(
          body: Center(child: Text("Ruta no encontrada")),
        ),
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

  late Future<void> consultabd;

  bool _loginLoading = false; // solo visual, tu lógica sigue igual

// ===================== API & USERAPI =====================
  final ApiService apiService = ApiService();
  late final UserApi userApi = UserApi(apiService);

  @override
  void initState() {
    super.initState();
    usuario.text = "";
    pass.text = "";
    claveAcceso.text = "";

    // Si quieres probar conexión, mejor un endpoint real (ping.php)
    apiService.postJson('ping.php', {}).then((data) {
      debugPrint('Ping: $data');
    }).catchError((e) {
      debugPrint('Error ping: $e');
    });
  }

  @override
  void dispose() {
    usuario.dispose();
    pass.dispose();
    claveAcceso.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_loginLoading) return;

    final user = usuario.text.trim();
    final pwd = pass.text.trim();

    setState(() => _loginLoading = true);

    final datosUsuario = await userApi.validarUsuario(user, pwd);

    if (!mounted) return;
    setState(() => _loginLoading = false);

    if (datosUsuario != null) {
      final idUsuario = datosUsuario['idUsuario'];
      final usuarioLogin = datosUsuario['usuario'];
      final nombre = datosUsuario['nombre'];
      final apellidoPaterno = datosUsuario['apellidoPaterno'];
      final apellidoMaterno = datosUsuario['apellidoMaterno'];

      final nom = "$nombre";
      final paterno = "$apellidoPaterno";
      final materno = "$apellidoMaterno";

      Navigator.pushReplacementNamed(
        context,
        '/captura',
        arguments: {
          'usuario': usuarioLogin,
          'idUsuario': idUsuario,
          'nombre': nom,
          'apellidoPaterno': paterno,
          'apellidoMaterno': materno,
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

    if (accesoConcedido) {
      claveAcceso.clear();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeAdmin()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceso concedido.')),
      );
    } else {
      claveAcceso.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceso denegado. Clave incorrecta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ permite ajustar con teclado
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.15),
              cs.surface,
              cs.surface,
            ],
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
                              child: Icon(Icons.local_gas_station,
                                  color: cs.primary, size: 28),
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
                                        fontWeight: FontWeight.w800),
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
                                    hintText: "Ingrese su contraseña",
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
                                    onPressed:
                                        _loginLoading ? null : _iniciarSesion,
                                    icon: _loginLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.login),
                                    label: Text(_loginLoading
                                        ? "Validando..."
                                        : "Iniciar sesión"),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: _abrirAdmin,
                                    icon:
                                        const Icon(Icons.admin_panel_settings),
                                    label:
                                        const Text("Opciones de administrador"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        //const Spacer(flex: 30), //sirve porque IntrinsicHeight + minHeight

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

  // ventana emergente para solicitar clave de acceso al registrar usuario
  Future<bool> mostrarDialogoClaveAcceso(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clave de Acceso Requerida'),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: claveAcceso,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Ingrese la clave de acceso',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final clave = await userApi
                    .validarAdmin(int.tryParse(claveAcceso.text.trim()) ?? 0);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(clave != null);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}
