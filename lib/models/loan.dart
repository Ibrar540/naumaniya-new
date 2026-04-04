class Loan {
  int? id;
  String description;
  String transactionType; // 'loan' or 'payment'
  double amount;
  String date;
  int? sectionId;
  String? sectionDocId;
  String? institution;
  DateTime? lastUpdated;

  Loan({
    this.id,
    required this.description,
    required this.transactionType,
    required this.amount,
    required this.date,
    this.sectionId,
    this.sectionDocId,
    this.institution,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'transaction_type': transactionType,
      'amount': amount,
      'section_id': sectionId,
      'institution': institution,
      'date': date,
      'lastUpdated': lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    double amountValue = 0.0;
    final amountField = map['amount'] ?? map['rs'];
    if (amountField != null) {
      if (amountField is double) amountValue = amountField;
      else if (amountField is int) amountValue = (amountField as int).toDouble();
      else if (amountField is String) amountValue = double.tryParse(amountField) ?? 0.0;
    }

    String dateValue = '';
    final dateField = map['date'];
    if (dateField != null) {
      if (dateField is DateTime) dateValue = dateField.toIso8601String().split('T')[0];
      else if (dateField is String) dateValue = dateField;
    }

    return Loan(
      id: map['id'],
      description: map['description'] ?? '',
      transactionType: map['transaction_type'] ?? map['type'] ?? 'loan',
      amount: amountValue,
      date: dateValue,
      sectionId: map['section_id'] ?? map['sectionId'],
      sectionDocId: map['sectionDocId'] != null ? map['sectionDocId'].toString() : null,
      institution: map['institution'] != null ? map['institution'].toString() : null,
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated'].toString()) : null,
    );
  }
}
