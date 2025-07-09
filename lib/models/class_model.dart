class ClassModel {
  int? id;
  String name;
  String createdAt;
  bool isSaved;

  ClassModel({
    this.id,
    required this.name,
    required this.createdAt,
    this.isSaved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      name: map['name'] ?? '',
      createdAt: map['created_at'] ?? '',
      isSaved: true,
    );
  }
} 