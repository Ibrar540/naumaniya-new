class User {
  final int? id;
  final String username;
  final String password;
  final String? name;
  final String? email;
  final String? phone;
  final String? institutionName;

  User({
    this.id,
    required this.username,
    required this.password,
    this.name,
    this.email,
    this.phone,
    this.institutionName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'institutionName': institutionName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      institutionName: map['institutionName'],
    );
  }
} 