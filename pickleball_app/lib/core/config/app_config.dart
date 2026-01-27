class AppConfig {
  // Base API URL - thay đổi theo môi trường của bạn
  static const String baseUrl = 'http://localhost:5240'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5240'; // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.x:5240'; // Real device
  
  static const String apiVersion = '/api';
  
  // API Endpoints
  static String get authLogin => '$baseUrl$apiVersion/Auth/login';
  static String get authRegister => '$baseUrl$apiVersion/Auth/register';
  static String get authMe => '$baseUrl$apiVersion/Auth/me';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
