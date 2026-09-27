import 'package:flutter/material.dart';
import '../calendarios/cal_reportesTarjetas.dart';
import '../calendarios/cal_verCortes.dart';
import 'adminUser/listadoUser.dart';

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
