import '../../core/network/api_client.dart';

class ScoreService {
  ScoreService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> obtenerTodas() async {
    final response = await _apiClient.dio.get('/puntuaciones');
    final data = response.data as List<dynamic>;

    return data
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }

  Future<void> guardarResultado({
    required int idUsuario,
    required String modo,
    required int digitos,
    required int vidas,
    required int tiempoPregunta,
    required int tiempoTotal,
    required int resultado,
  }) async {
    await _apiClient.dio.post(
      '/puntuaciones',
      data: {
        'idUsuario': idUsuario,
        'modo': modo,
        'digitos': digitos,
        'vidas': vidas,
        'tiempoPregunta': tiempoPregunta,
        'tiempoTotal': tiempoTotal,
        'resultado': resultado,
      },
    );
  }
}
