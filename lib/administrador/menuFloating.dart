import 'package:flutter/material.dart';
import '../calendarios/cal_generalTPV.dart';
import '../calendarios/cal_gral_consumos_clientes.dart';
import '../calendarios/cal_ingresoReportesTar.dart';
import '../calendarios/cal_reportesTarjetas.dart';
import '../calendarios/cal_verCortes.dart';
import 'adminUser/listadoUser.dart';
import 'authServise/authServise.dart';

// Floating menu for the administrator interface

class AdminFloatingMenu extends StatelessWidget {
  const AdminFloatingMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // se despliega menu para navegar en las diferentes secciones del administrador
        List<Widget> menuOptions = [
          ListTile(
            leading: const Icon(Icons.supervised_user_circle_rounded),
            title: const Text('Usuarios - administradores'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsuariosManejo()),
              );
              // Navegar a la sección 1
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_rounded),
            title: const Text('Visualizar Cortes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Cortes()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_rounded),
            title: const Text('Balance Tarjetas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalReporteTarjetas(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_rounded),
            title: const Text('Captura reportes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalIngresoReportesTar(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale_rounded),
            title: const Text('Cobros TPV'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalTPV()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station_rounded),
            title: const Text('Cargas clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalConsumoClientes(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await AuthService.cerrarSesion();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ];
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: menuOptions,
              ),
            );
          },
        );
      },
      child: const Icon(Icons.menu),
    );
  }
}
