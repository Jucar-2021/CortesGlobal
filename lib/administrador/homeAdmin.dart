import '../administrador/reportes/detalle_boucher.dart';
import 'package:flutter/material.dart';
import '../calendarios/cal_reportesTarjetas.dart';
import '../calendarios/cal_generalTPV.dart';
import '../calendarios/cal_verCortes.dart';
import 'bancos/bancos_manejo.dart';
import '../administrador/authServise/authServise.dart';
import '../administrador/adminUser/listadoUser.dart';
import 'clientes/manejoClientes.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Panel de Administrador",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService.cerrarSesion();
              Navigator.pushNamedAndRemoveUntil(context, '/login',(route) => false,);
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ================= ENCABEZADO SUPERIOR =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bienvenido",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Gestiona usuarios, cortes y reportes",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ================= GRID ==================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  _adminButton(
                    context,
                    icon: Icons.manage_accounts_rounded,
                    label: "Usuarios",
                    color: const Color(0xFF1E88E5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsuariosManejo(),
                        ),
                      );
                    },
                  ),
                  _adminButton(
                    context,
                    icon: Icons.assignment_rounded,
                    label: "Visualizar\nCortes",
                    color: const Color(0xFF7E57C2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Cortes(),
                        ),
                      );
                    },
                  ),
                  _adminButton(
                    context,
                    icon: Icons.credit_card_rounded,
                    label: "Balance de\nTarjetas",
                    color: const Color(0xFFE53935),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalReporteTarjetas(),
                        ),
                      );
                    },
                  ),
                  _adminButton(
                    context,
                    icon: Icons.edit_note_rounded,
                    label: "Global de cobros\nTPV",
                    color: const Color(0xFFFB8C00),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalTPV(),
                        ),
                      );
                    },
                  ),
                  _adminButton(
                    context,
                    icon: Icons.group_add,
                    label: "Gestion\nClientes",
                    color: const Color(0xFF6a8e8f),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Manejoclientes(),
                        ),
                      );
                    },
                  ),
                  _adminButton(
                    context,
                    icon: Icons.local_gas_station_rounded,
                    label: "Consumo\nClientes",
                    color: const Color(0xFF6a8e8f),
                    onTap: () {

                    },
                  ),

                  _adminButton(
                    context,
                    icon: Icons.assured_workload_rounded,
                    label: "Bancos",
                    color: const Color(0xFF6a8e8f),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BancosManejo(),
                        ),
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: color,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
