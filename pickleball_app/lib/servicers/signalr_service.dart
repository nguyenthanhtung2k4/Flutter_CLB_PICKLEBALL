import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _connection;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> init(String baseUrl, String token) async {
    if (_connection != null && _isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/pcmHub',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.onclose(({Exception? error}) {
      _isConnected = false;
    });

    await _connection!.start();
    _isConnected = true;
  }

  void listenToBookingUpdates(Function(dynamic) onBookingUpdate) {
    _connection?.on('UpdateCalendar', (args) {
      onBookingUpdate(args);
    });
  }

  void listenToNotification(Function(dynamic) onNotification) {
    _connection?.on('ReceiveNotification', (args) {
      if (args != null && args.isNotEmpty) {
        onNotification(args.first);
      } else {
        onNotification(null);
      }
    });
  }

  void listenToMatchScore(Function(dynamic) onMatchScore) {
    _connection?.on('UpdateMatchScore', (args) {
      if (args != null && args.isNotEmpty) {
        onMatchScore(args.first);
      } else {
        onMatchScore(null);
      }
    });
  }

  Future<void> stop() async {
    if (_connection != null) {
      await _connection!.stop();
    }
    _isConnected = false;
  }
}
