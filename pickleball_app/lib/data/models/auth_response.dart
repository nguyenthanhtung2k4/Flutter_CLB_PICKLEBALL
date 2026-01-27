class AuthResponse {
  final String token;
  final DateTime expiration;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.token,
    required this.expiration,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      expiration: DateTime.parse(json['expiration'] ?? DateTime.now().toIso8601String()),
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiration': expiration.toIso8601String(),
      'user': user,
    };
  }
}
