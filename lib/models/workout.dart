class Workout {
  final int? id;
  final String type;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime workoutDate;

  Workout({
    this.id,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.workoutDate,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as int?,
      type: json['type'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      workoutDate: json['workoutDate'] != null
          ? DateTime.parse(json['workoutDate'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'workoutDate': workoutDate.toIso8601String().split('.')[0],
      };
}
