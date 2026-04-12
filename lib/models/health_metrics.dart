class HealthMetrics {
  final String id;
  final int steps;
  final int heartRate;
  final double sleepHours;
  final double weight;
  final int calories;
  final DateTime recordedAt;

  HealthMetrics({
    required this.id,
    required this.steps,
    required this.heartRate,
    required this.sleepHours,
    required this.weight,
    required this.calories,
    required this.recordedAt,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      id: json['id'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
      heartRate: json['heartRate'] as int? ?? 0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'] as int? ?? 0,
      recordedAt: json['recordedAt'] != null 
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'steps': steps,
    'heartRate': heartRate,
    'sleepHours': sleepHours,
    'weight': weight,
    'calories': calories,
    'recordedAt': recordedAt.toIso8601String(),
  };
}
