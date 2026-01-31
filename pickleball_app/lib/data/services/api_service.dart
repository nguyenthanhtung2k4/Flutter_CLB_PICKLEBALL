import 'dart:typed_data';
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

  Future<Map<String, dynamic>> holdBooking(int courtId, DateTime startTime, DateTime endTime, {int holdMinutes = 5}) async {
    try {
      final response = await _dio.post('/bookings/hold', data: {
        'courtId': courtId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'holdMinutes': holdMinutes,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> confirmBooking(int holdId) async {
    try {
      await _dio.post('/bookings/confirm/$holdId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> releaseHold(int holdId) async {
    try {
      await _dio.delete('/bookings/hold/$holdId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createRecurringBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime recurUntil,
    required List<int> daysOfWeek,
    String frequency = 'Weekly',
  }) async {
    try {
      await _dio.post('/bookings/recurring', data: {
        'courtId': courtId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'recurUntil': recurUntil.toIso8601String(),
        'frequency': frequency,
        'daysOfWeek': daysOfWeek,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      await _dio.post('/bookings/cancel/$bookingId');
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

  // Matches APIs
  Future<List<dynamic>> getUpcomingMatches({int take = 10}) async {
    try {
      final response = await _dio.get('/matches/upcoming', queryParameters: {
        'take': take,
      });
      return response.data is List ? response.data : [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Member APIs
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get('/members/me/profile');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMembers({String? search, int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get('/members', queryParameters: {
        'search': search,
        'page': page,
        'pageSize': pageSize,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateMyProfile({String? fullName, String? avatarUrl}) async {
    try {
      await _dio.put('/members/me', data: {
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Admin APIs
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await _dio.get('/admin/dashboard/stats');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getRevenueChart({int days = 30}) async {
    try {
      final response = await _dio.get('/admin/dashboard/revenue', queryParameters: {
        'days': days,
      });
      return response.data is List ? response.data : [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final response = await _dio.get('/admin/dashboard/bookings-stats');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPendingDeposits({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get('/admin/wallet/pending-deposits', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> approveDeposit(int transactionId) async {
    try {
      await _dio.put('/admin/wallet/approve/$transactionId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> promoteMemberToAdmin(int memberId) async {
    try {
      await _dio.put('/admin/members/$memberId/promote-admin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createAdminMember({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      await _dio.post('/admin/members/create-admin', data: {
        'username': username,
        'email': email,
        'password': password,
        if (fullName != null) 'fullName': fullName,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Wallet APIs
  Future<void> depositWallet(
    double amount,
    String? description, {
    Uint8List? proofImageBytes,
    String? proofImageName,
    String? proofImageUrl,
  }) async {
    try {
      final formData = FormData.fromMap({
        'amount': amount,
        'description': description ?? 'Nạp tiền vào ví',
        if (proofImageBytes != null)
          'proofImage': MultipartFile.fromBytes(
            proofImageBytes,
            filename: proofImageName ?? 'proof.jpg',
          ),
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      });

      await _dio.post('/wallet/deposit', data: formData);
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
      return response.data['unreadCount'] ?? response.data['UnreadCount'] ?? 0;
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
        if (data is String) {
          return data;
        }
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        if (data is Map && data.containsKey('Message')) {
          return data['Message'];
        }
        if (data is Map && data.containsKey('errors')) {
          return data['errors'].toString();
        }
        return 'Lỗi: ${error.response!.statusMessage}';
      }
      return 'Lỗi kết nối: ${error.message}';
    }
    return 'Đã xảy ra lỗi không xác định';
  }
}
