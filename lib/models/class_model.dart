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
    // Handle created_at conversion from DateTime to String
    String createdAtStr;
    if (map['created_at'] is DateTime) {
      createdAtStr = (map['created_at'] as DateTime).toIso8601String();
    } else if (map['created_at'] is String) {
      createdAtStr = map['created_at'];
    } else {
      createdAtStr = DateTime.now().toIso8601String();
    }
    
    return ClassModel(
      id: map['id'],
      name: map['name'] ?? '',
      createdAt: createdAtStr,
      isSaved: true,
    );
  }
} 