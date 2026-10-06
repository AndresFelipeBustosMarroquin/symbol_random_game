import '../../core/network/api_client.dart';
import 'usuario_model.dart';

class UsuarioService {
  UsuarioService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<UsuarioResumen>> obtenerTodos() async {
    final response = await _apiClient.dio.get('/usuarios');

    final data = response.data as List<dynamic>;

    return data
        .map((json) => UsuarioResumen.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioModel> obtenerPorId(int id) async {
    final response = await _apiClient.dio.get('/usuarios/$id');

    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> crear(UsuarioModel usuario) async {
    final response = await _apiClient.dio.post(
      '/usuarios',
      data: usuario.toJson(),
    );

    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> iniciarSesion({
    required String nombreUso,
    required String contrasenaUs,
  }) async {
    final response = await _apiClient.dio.post(
      '/usuarios/login',
      data: {'nombreUso': nombreUso, 'contrasenaUs': contrasenaUs},
    );

    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> actualizar(int id, UsuarioModel usuario) async {
    final response = await _apiClient.dio.put(
      '/usuarios/$id',
      data: usuario.toJson(),
    );

    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar(int id, {required String contrasenaUs}) async {
    await _apiClient.dio.delete(
      '/usuarios/$id',
      data: {'contrasenaUs': contrasenaUs},
    );
  }
}
