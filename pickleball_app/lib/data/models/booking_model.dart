class BookingModel {
  final int id;
  final int courtId;
  final String courtName;
  final DateTime startTime;
  final DateTime endTime;
  final int status; // 0: Pending, 1: Confirmed, 2: Cancelled, 3: Completed, 4: Holding
  final String memberName;
  final int memberId;
  final DateTime? holdUntil;

  BookingModel({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.memberName,
    required this.memberId,
    this.holdUntil,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      courtId: json['courtId'],
      courtName: json['courtName'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      memberName: json['memberName'] ?? '',
      memberId: json['memberId'] ?? 0,
      holdUntil: json['holdUntil'] != null ? DateTime.tryParse(json['holdUntil']) : null,
    );
  }
}
