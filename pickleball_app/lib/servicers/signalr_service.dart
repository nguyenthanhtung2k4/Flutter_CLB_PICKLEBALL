import 'package:signalr_netcore/signalr_netcore.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  late HubConnection _hubConnection;
  
  // Singleton pattern
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> init(String baseUrl, String token) async {
    final serverUrl = '$baseUrl/hubs/pickleball'; // Adjust hub path
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
          
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection.onclose((error) {
      _isConnected = false;
      if (kDebugMode) {
        print("SignalR Connection Closed: $error");
      }
    });

    try {
      await _hubConnection.start();
      _isConnected = true;
      if (kDebugMode) {
        print("SignalR Connected to $serverUrl");
      }
    } catch (e) {
      if (kDebugMode) {
        print("SignalR Connection Error: $e");
      }
    }
  }

  void listenToBookingUpdates(Function(dynamic) onBookingUpdate) {
    if (!_isConnected) return;
    _hubConnection.on("ReceiveBookingUpdate", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        onBookingUpdate(arguments[0]);
      }
    });
  }

  void listenToNotification(Function(dynamic) onNotification) {
     if (!_isConnected) return;
    _hubConnection.on("ReceiveNotification", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        onNotification(arguments[0]);
      }
    });
  }

  Future<void> stop() async {
    if (_isConnected) {
      await _hubConnection.stop();
      _isConnected = false;
    }
  }
}
