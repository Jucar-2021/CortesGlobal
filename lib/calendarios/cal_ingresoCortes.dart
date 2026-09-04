import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/consumoPHP.dart';
import '../datosCorte.dart';
import '../api/cortes/manejoCortes_api.dart';
import '../administrador/authServise/authServise.dart';

class Captura extends StatelessWidget {
  final String usuario;
  final int idUsuario;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  const Captura({
    super.key,
    required this.usuario,
    required this.idUsuario,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  @override
  Widget build(BuildContext context) {
    return Ingreso(
      usuario: usuario,
      idUsuario: idUsuario,
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
    );
  }
}

class Ingreso extends StatefulWidget {
  const Ingreso({
    super.key,
    required this.usuario,
    required this.idUsuario,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });
  final String usuario;
  final int idUsuario;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  @override
  State<Ingreso> createState() => _IngresoState();
}

class _IngresoState extends State<Ingreso> {
  final TextEditingController _fechaSelec = TextEditingController();
  final TextEditingController _fechaVisual = TextEditingController();
  DateTime? _fechaSeleccionada;
  String? turnoSeleccionado;

  late String user;
  late int idUsuario;
  late String nombre;
  late String apellidoPaterno;
  late String apellidoMaterno;

  late final ApiService apiService;
  late ManejocortesApi validacionCorteApi;

  @override
  void initState() {
    super.initState();
    user = widget.usuario;
    idUsuario = widget.idUsuario;
    nombre = widget.nombre;
    apellidoPaterno = widget.apellidoPaterno;
    apellidoMaterno = widget.apellidoMaterno;

    apiService = ApiService();
    validacionCorteApi = ManejocortesApi(apiService);
  }

  @override
  void dispose() {
    _fechaSelec.dispose();
    _fechaVisual.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 5),
      locale: const Locale('es', 'MX'),
      useRootNavigator: true,
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionada = fecha;

        // valor real
        _fechaSelec.text = DateFormat('yyyy/MM/dd').format(fecha);

        // valor visual
        _fechaVisual.text = DateFormat(
          "d 'de' MMMM 'del' yyyy",
          'es_MX',
        ).format(fecha);
      });
    }
  }

  Future<void> _continuar() async {
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha primero')),
      );
      return;
    }

    if (turnoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona el turno en que abriste tu turno para continuar',
          ),
        ),
      );
      return;
    }
    final fecha = _fechaSelec.text;
    if (!_validarFechaSeleccionada()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes seleccionar una fecha tan lejana al día actual',
          ),
        ),
      );
      return;
    }

    final idCorte = await _validarCorte(fecha, idUsuario, turnoSeleccionado!);

    if (idCorte != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
          title: const Text(
            'Corte ya registrado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$nombre ya tienes un corte registrado para la fecha ${_formatoFecha(fecha)} y turno $turnoSeleccionado.',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Para modificar o corregir, contacta al administrador.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo
              },
              child: const Text(
                'Aceptar y continuar',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DatoCorte(
            fecha: fecha,
            user: user,
            idUsuario: idUsuario,
            nombre: nombre,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: apellidoMaterno,
            turno: turnoSeleccionado!,
          ),
        ),
      );
    }
  }

  Future<int?> _validarCorte(String fecha, int idUsuario, String turno) async {
    try {
      final idCorte = await validacionCorteApi.validarCorteRegistrado(
        idUsuario: idUsuario,
        fecha: fecha,
        turno: turnoSeleccionado!,
      );
      return idCorte;
    } catch (e) {
      print('Error al validar corte en fecha: $e');
      return null;
    }
  }

  // Aqui se obtine la fecha del dispositivo para comparacion de la fecha seleccionada,
  // esto es para evitar que se capture una fecha futura o muy antigua.
  bool _validarFechaSeleccionada() {
    final hoy = DateTime.now();
    final fechaLimiteInferior = DateTime(hoy.year, hoy.month, hoy.day - 10);
    final fechaLimiteSuperior = DateTime(hoy.year, hoy.month, hoy.day + 2);

    return _fechaSeleccionada!.isAfter(fechaLimiteInferior) &&
        _fechaSeleccionada!.isBefore(fechaLimiteSuperior);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // Esto ayuda cuando aparece teclado
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fecha de corte",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              "Bienvenido: $nombre $apellidoPaterno $apellidoMaterno",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
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
          child: Align(
            alignment: Alignment.topCenter,

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // Encabezado tipo "sección"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Selecciona la fecha para cartura de corte",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Elige la fecha que vas a capturar para continuar.",
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card principal
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
                            TextField(
                              controller: _fechaVisual,
                              readOnly: true,
                              onTap: _seleccionarFecha,
                              decoration: InputDecoration(
                                labelText: 'Fecha',
                                hintText: 'Selecciona una fecha',
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.event),
                                  onPressed: _seleccionarFecha,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            //aui se seleciona el tipo de venta si es gasolina o diesel,
                            //de esta forma se identidicara el tipo de corte,
                            const SizedBox(height: 10),

                            Text(
                              "Horario de inicio de turno",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text("Mañana"),
                                    value: "Mañana",
                                    // ignore: deprecated_member_use
                                    groupValue: turnoSeleccionado,
                                    // ignore: deprecated_member_use
                                    onChanged: (value) => setState(
                                      () => turnoSeleccionado = value,
                                    ),
                                  ),
                                  Divider(height: 1, color: cs.outlineVariant),
                                  RadioListTile<String>(
                                    title: const Text("Tarde"),
                                    value: "Tarde",
                                    groupValue: turnoSeleccionado,
                                    // ignore: deprecated_member_use
                                    onChanged: (value) => setState(
                                      () => turnoSeleccionado = value,
                                    ),
                                  ),
                                  Divider(height: 1, color: cs.outlineVariant),
                                  RadioListTile<String>(
                                    title: const Text("Noche"),
                                    value: "Noche",
                                    groupValue: turnoSeleccionado,
                                    // ignore: deprecated_member_use
                                    onChanged: (value) => setState(
                                      () => turnoSeleccionado = value,
                                    ),
                                  ),
                                  Divider(height: 1, color: cs.outlineVariant),
                                  RadioListTile<String>(
                                    title: const Text("Mixto"),
                                    value: "Mixto",
                                    groupValue: turnoSeleccionado,
                                    // ignore: deprecated_member_use
                                    onChanged: (value) => setState(
                                      () => turnoSeleccionado = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                            SizedBox(
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: _continuar,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text(
                                  "Continuar",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer discreto
                    Text(
                      "Consejo: si capturas siempre al cierre, elige la fecha del día enque abriste turno.",
                      style: TextStyle(
                        fontSize: 12,
                        // ignore: deprecated_member_use
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //formato de fecha DD/MM/YYYY
  String _formatoFecha(String fecha) {
    try {
      final partes = fecha.split('/');
      if (partes.length != 3) return fecha;

      final an = partes[0];
      final mes = partes[1];
      final dia = partes[2];

      return '$dia/$mes/$an';
    } catch (e) {
      return fecha;
    }
  }
}
