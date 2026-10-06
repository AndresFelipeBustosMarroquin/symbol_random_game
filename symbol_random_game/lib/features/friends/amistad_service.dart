import '../../core/network/api_client.dart';
import 'amistad_model.dart';

class AmistadService {
  AmistadService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AmistadesUsuario> obtener(int userId) async {
    final response = await _apiClient.dio.get(
      '/usuarios/$userId/amistades',
    );
    return AmistadesUsuario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EstadoAmistad> estado(int userId, int otherId) async {
    final response = await _apiClient.dio.get(
      '/usuarios/$userId/amistades/$otherId',
    );
    return EstadoAmistad.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> solicitar(int userId, int targetId) async {
    await _apiClient.dio.post('/usuarios/$userId/amistades/$targetId');
  }

  Future<void> aceptar(int userId, int requesterId) async {
    await _apiClient.dio.post(
      '/usuarios/$userId/amistades/$requesterId/aceptar',
    );
  }

  Future<void> eliminar(int userId, int otherId) async {
    await _apiClient.dio.delete('/usuarios/$userId/amistades/$otherId');
  }
}
