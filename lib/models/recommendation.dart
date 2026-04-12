class Recommendation {
  final String id;
  final String type; // nutrition, workout, health
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'nutrition',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
  };
}
