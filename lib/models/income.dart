class Income {
  int? id;
  String description;
  double amount;
  String date;
  bool isSaved;
  int? sectionId;
  String? sectionDocId;
  String? institution;
  DateTime? lastUpdated;

  Income({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.isSaved = false,
    this.sectionId,
    this.sectionDocId,
    this.institution,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'section_id': sectionId,
      'institution': institution,
      'date': date,
      'type': 'income',
      'lastUpdated':
          lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    double amountValue = 0.0;
    // Support both 'amount' and 'rs' field names
    final amountField = map['amount'] ?? map['rs'];
    if (amountField != null) {
      if (amountField is double) {
        amountValue = amountField;
      } else if (amountField is int) {
        amountValue = (amountField as int).toDouble();
      } else if (amountField is String) {
        amountValue = double.tryParse(amountField) ?? 0.0;
      }
    }
    
    // Parse date field - handle both DateTime and String
    String dateValue = '';
    final dateField = map['date'];
    if (dateField != null) {
      if (dateField is DateTime) {
        dateValue = dateField.toIso8601String().split('T')[0]; // Format as yyyy-MM-dd
      } else if (dateField is String) {
        dateValue = dateField;
      }
    }
    
    return Income(
      id: map['id'],
      description: map['description'] ?? '',
      amount: amountValue,
      date: dateValue,
      isSaved: true,
      sectionId: map['section_id'] ?? map['sectionId'],
      sectionDocId: map['sectionDocId'] != null ? map['sectionDocId'].toString() : null,
      institution: map['institution'] != null ? map['institution'].toString() : null,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString())
          : null,
    );
  }
}
