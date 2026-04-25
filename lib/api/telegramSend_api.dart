import 'consumoPHP.dart';

class TelegramApi {
  final ApiService api;

  TelegramApi(this.api);

  Future<void> sendMessage(String mensaje) async {
    try {
      await api.postJson(
        'avisos/enviar.php',
        {
          'mensaje': mensaje,
        },
      );
    } catch (e) {
      throw Exception('Error enviando mensaje a Telegram: $e');
    }
  }
}
