import 'package:flutter/material.dart';
import '../calendarios/cal_reportesTarjetas.dart';
import '../calendarios/cal_generalTPV.dart';
import '../calendarios/cal_verCortes.dart';
import 'bancos/bancos_manejo.dart';
import '../administrador/authServise/authServise.dart';
import '../administrador/adminUser/listadoUser.dart';
import 'clientes/manejoClientes.dart';
import '../calendarios/cal_gral_consumos_clientes.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF3F6FA);
  static const Color textColor = Color(0xFF263238);

  @override
  Widget build(BuildContext context) {
    final opciones = [
      _AdminOption(
        icon: Icons.manage_accounts_rounded,
        title: "Usuarios",
        subtitle: "Administrar accesos",
        color: const Color(0xFF1E88E5),
        page: const UsuariosManejo(),
      ),
      _AdminOption(
        icon: Icons.assignment_rounded,
        title: "Visualizar Cortes",
        subtitle: "Revisión de cortes",
        color: const Color(0xFF7E57C2),
        page: Cortes(),
      ),
      _AdminOption(
        icon: Icons.credit_card_rounded,
        title: "Balance Tarjetas",
        subtitle: "Reportes bancarios",
        color: const Color(0xFFE53935),
        page: const CalReporteTarjetas(),
      ),
      _AdminOption(
        icon: Icons.point_of_sale_rounded,
        title: "Cobros TPV",
        subtitle: "Consulta global",
        color: const Color(0xFFFB8C00),
        page: const CalTPV(),
      ),
      _AdminOption(
        icon: Icons.groups_rounded,
        title: "Clientes",
        subtitle: "Gestión de clientes",
        color: const Color(0xFF00897B),
        page: const Manejoclientes(),
      ),
      _AdminOption(
        icon: Icons.local_gas_station_rounded,
        title: "Consumos",
        subtitle: "Consumo de clientes",
        color: const Color(0xFF43A047),
        page: const CalConsumoClientes(),
      ),
      _AdminOption(
        icon: Icons.account_balance_rounded,
        title: "Bancos",
        subtitle: "Catálogo bancario",
        color: const Color(0xFF546E7A),
        page: const BancosManejo(),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Panel Administrativo",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Cerrar sesión",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService.cerrarSesion();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _HeaderAdmin(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: opciones.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final item = opciones[index];

                    return _AdminCard(
                      option: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.page),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.28)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bienvenido",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Gestiona cortes, bancos, clientes y reportes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final _AdminOption option;
  final VoidCallback onTap;

  const _AdminCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        splashColor: option.color.withOpacity(0.10),
        highlightColor: option.color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(option.icon, color: option.color, size: 32),
              ),
              const Spacer(),
              Text(
                option.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeAdmin.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "Abrir",
                    style: TextStyle(
                      color: option.color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: option.color,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const _AdminOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}
