import '../administrador/reportesTarjetas.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewReportesTarjetas extends StatelessWidget {
  const ViewReportesTarjetas({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalReporteTarjetas();
  }
}

class CalReporteTarjetas extends StatefulWidget {
  const CalReporteTarjetas({super.key});

  @override
  State<CalReporteTarjetas> createState() => _CalReporteTarjetasState();
}

class _CalReporteTarjetasState extends State<CalReporteTarjetas> {
  final TextEditingController _fechaIni = TextEditingController();
  final TextEditingController _fechaFin = TextEditingController();
  final TextEditingController _fechaVisualini = TextEditingController();
  final TextEditingController _fechaVisualFin = TextEditingController();
  DateTime? _fechaSeleccionadaini;
  DateTime? _fechaSeleccionadaFin;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fechaIni.dispose();
    _fechaFin.dispose();
    _fechaVisualini.dispose();
    _fechaVisualFin.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha1() async {
    final hoy = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionadaini ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 5),
      locale: const Locale('es', 'MX'),
      useRootNavigator: true,
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionadaini = fecha;

        // valor real
        _fechaIni.text = DateFormat('yyyy/MM/dd').format(fecha);

        // valor visual
        _fechaVisualini.text =
            DateFormat("d 'de' MMMM 'del' yyyy", 'es_MX').format(fecha);
      });
    }
  }

  Future<void> _seleccionarFecha2() async {
    final hoy = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionadaFin ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 5),
      locale: const Locale('es', 'MX'),
      useRootNavigator: true,
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionadaFin = fecha;

        // valor real
        _fechaFin.text = DateFormat('yyyy/MM/dd').format(fecha);

        // valor visual
        _fechaVisualFin.text =
            DateFormat("d 'de' MMMM 'del' yyyy", 'es_MX').format(fecha);
      });
    }
  }

  void _continuar() {
    if (_fechaSeleccionadaini == null && _fechaSeleccionadaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ingresa el periodo a consultar')),
      );
      return;
      //Validacion si la fecha de fin es anterior a la fecha de inicio
    } else if (_fechaSeleccionadaFin != null && _fechaSeleccionadaini != null) {
      if (_fechaSeleccionadaFin!.isBefore(_fechaSeleccionadaini!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'La fecha de inicio no puede ser posterior a la fecha de fin')),
        );
        return;
      }
    }

    final fechaini = _fechaIni.text;
    final fechafin = _fechaFin.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReporteTarjetas(
          fechaini: fechaini,
          fechafin: fechafin,
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
              "Reportes de tarjetas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              "Selecciona el periodo a consultar",
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
                              controller: _fechaVisualini,
                              readOnly: true,
                              onTap: _seleccionarFecha1,
                              decoration: InputDecoration(
                                labelText: 'Fecha de inicio',
                                hintText: 'Fecha de inicio',
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.event),
                                  onPressed: _seleccionarFecha1,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              controller: _fechaVisualFin,
                              readOnly: true,
                              onTap: _seleccionarFecha2,
                              decoration: InputDecoration(
                                labelText: 'Fecha de fin',
                                hintText: 'Fecha de fin',
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.event),
                                  onPressed: _seleccionarFecha2,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

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
                      "Nota: Selecciona un rango de fechas a consultar.",
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
