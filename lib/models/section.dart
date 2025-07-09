class Section {
  final int? id;
  final String name;
  final String institution; // 'madrasa' or 'masjid'
  final String type; // 'income' or 'expenditure'

  Section({this.id, required this.name, required this.institution, required this.type});

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'] as int?,
      name: map['name'] as String,
      institution: map['institution'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institution': institution,
      'type': type,
    };
  }
} 