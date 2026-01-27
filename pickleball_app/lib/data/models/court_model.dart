class CourtModel {
  final int id;
  final String name;
  final double pricePerHour;
  final String? description;
  final bool isActive;

  CourtModel({
    required this.id,
    required this.name,
    required this.pricePerHour,
    this.description,
    required this.isActive,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'],
      name: json['name'],
      pricePerHour: (json['pricePerHour'] ?? 0.0).toDouble(),
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}
