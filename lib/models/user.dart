class User {
  final int id;
  final String username;
  final String realName;
  final String role;
  final String email;
  final String createdAt;
  final int competitionCount;
  final int certificateCount;

  User({
    required this.id,
    required this.username,
    required this.realName,
    required this.role,
    required this.email,
    required this.createdAt,
    required this.competitionCount,
    required this.certificateCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      realName: json['realName'] ?? '',
      role: json['role'] ?? 'USER',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] ?? '',
      competitionCount: json['competitionCount'] ?? 0,
      certificateCount: json['certificateCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'realName': realName,
      'role': role,
      'email': email,
      'createdAt': createdAt,
      'competitionCount': competitionCount,
      'certificateCount': certificateCount,
    };
  }
}