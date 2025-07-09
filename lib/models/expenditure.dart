class Expenditure {
  int? id;
  String description;
  double amount;
  String date;
  bool isSaved;

  Expenditure({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.isSaved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date,
    };
  }

  factory Expenditure.fromMap(Map<String, dynamic> map) {
    double amountValue = 0.0;
    if (map['amount'] != null) {
      if (map['amount'] is double) {
        amountValue = map['amount'];
      } else if (map['amount'] is int) {
        amountValue = (map['amount'] as int).toDouble();
      } else if (map['amount'] is String) {
        amountValue = double.tryParse(map['amount']) ?? 0.0;
      }
    }
    return Expenditure(
      id: map['id'],
      description: map['description'] ?? '',
      amount: amountValue,
      date: map['date'] ?? '',
      isSaved: true,
    );
  }
} 