class User {
  final String id;
  final String fullName;
  final String email;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String goal;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      gender: json['gender'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'age': age,
    'weight': weight,
    'height': height,
    'gender': gender,
    'goal': goal,
  };
}
