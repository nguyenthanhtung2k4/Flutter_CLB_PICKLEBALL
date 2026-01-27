import 'package:flutter/foundation.dart';

/// SignalR Service Stub - Real-time functionality disabled temporarily
/// TODO: Re-enable SignalR when package cache is fixed
class SignalRService {
  // Singleton pattern
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> init(String baseUrl, String token) async {
    // SignalR disabled - just log and skip
    if (kDebugMode) {
      print("SignalR: Disabled (package unavailable). Skipping connection to $baseUrl");
    }
    _isConnected = false;
  }

  void listenToBookingUpdates(Function(dynamic) onBookingUpdate) {
    // No-op: SignalR disabled
    if (kDebugMode) {
      print("SignalR: listenToBookingUpdates - disabled");
    }
  }

  void listenToNotification(Function(dynamic) onNotification) {
    // No-op: SignalR disabled
    if (kDebugMode) {
      print("SignalR: listenToNotification - disabled");
    }
  }

  Future<void> stop() async {
    _isConnected = false;
  }
}
