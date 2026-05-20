import 'package:flutter/material.dart';
import '../adminUser/registroUser.dart';
import '../../api/user/adminUser_api.dart';
import '../../api/consumoPHP.dart';


class UsuariosManejo extends StatefulWidget {
  const UsuariosManejo({super.key});

  @override
  State<UsuariosManejo> createState() => _UsuariosManejoState();
}

class _UsuariosManejoState extends State<UsuariosManejo> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: UserAdminApi(ApiService()).getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text('${user['nombre'] ?? ''} ${user['apellidoPaterno'] ?? ''}'),
                  subtitle: Text(user['usuario'] ?? 'Sin nombre'),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Registro())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
