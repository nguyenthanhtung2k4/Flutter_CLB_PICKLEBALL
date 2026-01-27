class UserModel {
  final String id;
  final String username;
  final String email;
  final int memberId;
  final String fullName;
  final double walletBalance;
  final String? avatarUrl;
  final String tier;
  final double rankLevel;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.memberId,
    required this.fullName,
    required this.walletBalance,
    this.avatarUrl,
    required this.tier,
    required this.rankLevel,
    this.role = 'User',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['userName'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      memberId: json['memberId'] ?? 0,
      fullName: json['fullName'] ?? '',
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      avatarUrl: json['avatarUrl'],
      tier: json['tier']?.toString() ?? 'Standard',
      rankLevel: (json['rankLevel'] ?? 0.0).toDouble(),
      role: json['roles'] != null && (json['roles'] as List).contains('Admin') ? 'Admin' : 'User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': username,
      'email': email,
      'memberId': memberId,
      'fullName': fullName,
      'walletBalance': walletBalance,
      'avatarUrl': avatarUrl,
      'tier': tier,
      'rankLevel': rankLevel,
    };
  }
}
