import 'package:symbol_random_game/core/network/api_client.dart';
import 'package:symbol_random_game/features/settings/data/configuracion_model.dart';

class ConfiguracionService {
  ConfiguracionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ConfiguracionUsuario> obtener(int userId) async {
    final response = await _apiClient.dio.get(
      '/usuarios/$userId/configuracion',
    );
    return ConfiguracionUsuario.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> guardar(int userId, ConfiguracionUsuario config) async {
    await _apiClient.dio.put(
      '/usuarios/$userId/configuracion',
      data: config.toJson(),
    );
  }
}
