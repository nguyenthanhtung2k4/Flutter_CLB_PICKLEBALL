import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../models/court_model.dart';
import '../models/booking_model.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl + AppConfig.apiVersion,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid - clear storage
          await _storage.delete(key: AppConfig.tokenKey);
          await _storage.delete(key: AppConfig.userKey);
        }
        return handler.next(error);
      },
    ));
  }

  // Auth APIs
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Booking APIs
  Future<List<CourtModel>> getCourts() async {
    try {
      final response = await _dio.get('/courts');
      return (response.data as List).map((e) => CourtModel.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BookingModel>> getBookings(DateTime from, DateTime to) async {
    try {
      final response = await _dio.get('/bookings/calendar', queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
      return (response.data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createBooking(int courtId, DateTime startTime, DateTime endTime) async {
    try {
      await _dio.post('/bookings', data: {
        'courtId': courtId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Tournament APIs
  Future<List<dynamic>> getTournaments({String? status}) async {
    try {
      final response = await _dio.get('/tournaments', queryParameters: {
        if (status != null) 'status': status,
      });
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> joinTournament(int tournamentId, {String? teamName}) async {
    try {
      await _dio.post('/tournaments/$tournamentId/join', queryParameters: {
        if (teamName != null) 'teamName': teamName,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> getTournamentDetail(int tournamentId) async {
    try {
      final response = await _dio.get('/tournaments/$tournamentId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Wallet APIs
  Future<void> depositWallet(double amount, String? description, {String? proofImageUrl}) async {
    try {
      await _dio.post('/wallet/deposit', data: {
        'amount': amount,
        'description': description ?? 'Nạp tiền vào ví',
        'proofImageUrl': proofImageUrl,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getWalletTransactions() async {
    try {
      final response = await _dio.get('/wallet/transactions');
      return response.data is List ? response.data : (response.data['data'] ?? []);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Notifications APIs
  Future<Map<String, dynamic>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['unreadCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Storage helpers
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        if (data is Map && data.containsKey('Message')) {
          return data['Message'];
        }
        return 'Lỗi: ${error.response!.statusMessage}';
      }
      return 'Lỗi kết nối: ${error.message}';
    }
    return 'Đã xảy ra lỗi không xác định';
  }
}
