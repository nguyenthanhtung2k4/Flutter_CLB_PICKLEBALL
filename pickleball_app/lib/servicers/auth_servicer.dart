import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AuthService {
  final ApiClient api;
  final TokenStorage storage;

  AuthService(this.api, this.storage);

  Future<AuthResponse> login(String email, String password) async {
    final res = await api.dio.post("/api/auth/login", data: {
      "email": email,
      "password": password,
    });

    final auth = AuthResponse.fromJson(res.data);
    await storage.saveToken(auth.accessToken);
    return auth;
  }

  Future<AuthResponse> register(String email, String password) async {
    final res = await api.dio.post("/api/auth/register", data: {
      "email": email,
      "password": password,
    });

    final auth = AuthResponse.fromJson(res.data);
    await storage.saveToken(auth.accessToken);
    return auth;
  }

  Future<void> logout() => storage.clear();

  Future<Map<String, dynamic>> me() async {
    final res = await api.dio.get("/api/auth/me");
    return res.data;
  }
}
