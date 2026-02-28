class Section {
  final int? id;
  final String? docId;
  final String name;
  final String institution; // 'madrasa' or 'masjid'
  final String type; // 'income' or 'expenditure'
  DateTime? lastUpdated;

  Section({
    this.docId,
    this.id,
    required this.name,
    required this.institution,
    required this.type,
    this.lastUpdated,
  });

  factory Section.fromMap(Map<String, dynamic> map) {
    // Normalize id: it may come as int or String (Firestore doc id). Try to parse to int when possible.
    int? idValue;
    if (map['id'] != null) {
      if (map['id'] is int) {
        idValue = map['id'] as int;
      } else {
        idValue = int.tryParse(map['id'].toString());
      }
    }
    return Section(
      id: idValue,
      docId: map['docId'] != null ? map['docId'].toString() : null,
      name: map['name'],
      institution: map['institution'],
      type: map['type'],
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'docId': docId,
      'name': name,
      'institution': institution,
      'type': type,
      'lastUpdated':
          lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
