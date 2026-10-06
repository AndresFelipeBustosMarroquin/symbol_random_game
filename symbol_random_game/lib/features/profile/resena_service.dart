import '../../core/network/api_client.dart';
import 'resena_model.dart';

class ResenaService {
  ResenaService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ResenaPerfil>> obtener(int profileId) async {
    final response = await _apiClient.dio.get('/usuarios/$profileId/resenas');
    final data = response.data as List<dynamic>;
    return data
        .map((json) => ResenaPerfil.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ResenaPerfil> guardar({
    required int profileId,
    required int authorId,
    required String content,
  }) async {
    final response = await _apiClient.dio.post(
      '/usuarios/$profileId/resenas',
      data: {'idAutor': authorId, 'contenido': content},
    );
    return ResenaPerfil.fromJson(response.data as Map<String, dynamic>);
  }
}
