import '../consumoPHP.dart';

class UserAdminApi {
  final ApiService api;
  UserAdminApi(this.api);

  Future<List<Map<String, dynamic>>> getUser() async {
    final res = await api.postJson('User/listar.php', {});
    final data = res['data'];

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Respuesta inesperada: "data" no es una lista');
    }
  }

  Future <void> updatePassword(int idUsuario, String pass) async {

    await api.postJson('User/updatePass.php', {
      'idUsuario': idUsuario,
      'pass': pass,
    });
  }
}
