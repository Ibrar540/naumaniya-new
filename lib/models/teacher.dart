import 'package:intl/intl.dart';

class Teacher {
  int? id;
  String name;
  String mobile;
  DateTime? startingDate;
  String status;
  String leavingDate;
  int salary;
  bool isSaved;

  Teacher({
    this.id,
    required this.name,
    this.mobile = '',
    this.startingDate,
    this.status = '',
    this.leavingDate = '',
    this.salary = 0,
    this.isSaved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'startingDate': startingDate != null ? DateFormat('yyyy-MM-dd').format(startingDate!) : null,
      'status': status,
      'leavingDate': leavingDate,
      'salary': salary,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    DateTime? parseStartingDate;
    if (map['startingDate'] != null && map['startingDate'].toString().isNotEmpty) {
      try {
        parseStartingDate = DateTime.tryParse(map['startingDate'].toString());
      } catch (e) {
        // If parsing fails, set to null
        parseStartingDate = null;
      }
    }
    
    int salaryValue = 0;
    if (map['salary'] != null) {
      if (map['salary'] is int) {
        salaryValue = map['salary'];
      } else if (map['salary'] is String) {
        salaryValue = int.tryParse(map['salary']) ?? 0;
      }
    }
    
    return Teacher(
      id: map['id'],
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      startingDate: parseStartingDate,
      status: map['status'] ?? '',
      leavingDate: map['leavingDate'] ?? '',
      salary: salaryValue,
      isSaved: true,
    );
  }
} 