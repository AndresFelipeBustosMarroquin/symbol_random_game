import 'package:symbol_random_game/core/network/api_client.dart';
import 'package:symbol_random_game/features/profile/domain/perfil_model.dart';

class PerfilService {
  PerfilService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PerfilUsuario> obtener(int userId) async {
    final response = await _apiClient.dio.get('/usuarios/$userId/perfil');
    return PerfilUsuario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PerfilUsuario> actualizar(
    int userId,
    PerfilUsuario perfil,
  ) async {
    final response = await _apiClient.dio.put(
      '/usuarios/$userId/perfil',
      data: perfil.toJson(),
    );
    return PerfilUsuario.fromJson(response.data as Map<String, dynamic>);
  }
}
