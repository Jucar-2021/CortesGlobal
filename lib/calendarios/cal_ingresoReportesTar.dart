import '../tarjetasCajero/ingresoTirasTarje.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewReportes extends StatelessWidget {
  const ViewReportes({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalIngresoReportesTar();
  }
}

class CalIngresoReportesTar extends StatefulWidget {
  const CalIngresoReportesTar({super.key});

  @override
  State<CalIngresoReportesTar> createState() => _CalIngresoReportesTarState();
}

class _CalIngresoReportesTarState extends State<CalIngresoReportesTar> {
  final TextEditingController _fechaSelec = TextEditingController();
  final TextEditingController _fechaVisual = TextEditingController();
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
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
        _fechaVisual.text =
            DateFormat("d 'de' MMMM 'del' yyyy", 'es_MX').format(fecha);
      });
    }
  }

  void _continuar() {
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha primero')),
      );
      return;
    }

    final fecha = _fechaSelec.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngresoReportes(
          fecha: fecha,
        ),
      ),
    );
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
              "Fecha",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              "Ingresa la fecha para ingresar los reportes",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
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
            colors: [
              cs.primary.withOpacity(0.12),
              cs.surface,
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // Encabezado tipo "sección"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Seleccion de fecha",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
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

                    const Spacer(),

                    // Footer discreto
                    Text(
                      "Nota: solo se veran los cortes cerrados.",
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
}
