class User {
  final int id;
  final String name;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'isActive': isActive,
    };
  }

  bool get isAdmin => role == 'admin';
}

class AuthResponse {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  AuthResponse({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      error: json['error'],
    );
  }
}
