import 'package:symbol_random_game/core/network/api_client.dart';
import 'package:symbol_random_game/features/chat/domain/chat_model.dart';

class ChatService {
  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  String _path(int userId, int friendId) =>
      '/usuarios/$userId/chats/$friendId/mensajes';

  Future<List<MensajeChat>> obtener(int userId, int friendId) async {
    final response = await _apiClient.dio.get(_path(userId, friendId));
    final messages = response.data as List<dynamic>;
    return messages
        .map(
          (message) =>
              MensajeChat.fromJson(message as Map<String, dynamic>),
        )
        .toList();
  }

  Future<MensajeChat> enviar({
    required int userId,
    required int friendId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post(
      _path(userId, friendId),
      data: {'contenido': content},
    );
    return MensajeChat.fromJson(response.data as Map<String, dynamic>);
  }
}
