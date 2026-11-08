import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/consumoPHP.dart';

class CortesDia extends StatelessWidget {
  final String fecha;

  CortesDia({super.key, required this.fecha});

  Future<void> _obtenerCorteGeneralPorDia(BuildContext context) async {
    final apiService = ApiService();
    try {
      final response = await apiService.postJson('corteGeneralPorDia', {
        'fecha': fecha,
      });

      // Manejar la respuesta según sea necesario
      print('Respuesta del servidor: $response');
    } catch (e) {
      // Manejar errores
      print('Error al obtener el corte general: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cortes del Día')),
      body: Center(
        child: Text(
          'Contenido de los cortes del día para la fecha ${_formatoFecha(fecha)}',
        ),
      ),
    );
  }

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
