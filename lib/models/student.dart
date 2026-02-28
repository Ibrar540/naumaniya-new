import 'package:intl/intl.dart';

class Student {
  int? id;
  String? studentId;
  int? rollNo;
  String name;
  String fatherName;
  String mobile;
  DateTime admissionDate;
  String fee;
  String status;
  String struckOffDate;
  String graduationDate;
  String leftDate;
  int? classId;
  String? className;  // Added className field
  bool isSaved;

  Student({
    this.id,
    this.studentId,
    this.rollNo,
    required this.name,
    required this.fatherName,
    required this.mobile,
    required this.admissionDate,
    required this.fee,
    this.status = '',
    this.struckOffDate = '',
    this.graduationDate = '',
    this.leftDate = '',
    this.classId,
    this.className,  // Added className parameter
    this.isSaved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'roll_no': rollNo,
      'name': name,
      'fatherName': fatherName,
      'mobile': mobile,
      'admissionDate': DateFormat('yyyy-MM-dd').format(admissionDate),
      'fee': fee,
      'status': status,
      'struckOffDate': struckOffDate,
      'graduationDate': graduationDate,
      'leftDate': leftDate,
      'classId': classId,
      'class': className,  // Added className to map
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    DateTime parseAdmissionDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      // Handle DateTime object (from PostgreSQL)
      if (dateValue is DateTime) {
        return dateValue;
      }
      // Handle String (from old data or JSON)
      if (dateValue is String) {
        if (dateValue.isEmpty || dateValue == 'none') {
          return DateTime.now();
        }
        try {
          return DateFormat('yyyy-MM-dd').parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Student(
      id: map['id'],
      studentId: map['student_id'],
      rollNo: map['roll_no'],
      name: map['name'] ?? '',
      fatherName: map['father_name'] ?? map['fatherName'] ?? '',
      mobile: map['mobile'] ?? map['mobile_no']?.toString() ?? '',
      admissionDate: parseAdmissionDate(map['admission_date'] ?? map['admissionDate']),
      fee: (map['fee'] ?? '').toString(),
      status: (map['status'] ?? '').toString().trim().isEmpty
          ? 'Active'
          : map['status'],
      struckOffDate: (map['struck_off_date'] ?? map['struckOffDate'] ?? '').toString(),
      graduationDate: (map['graduation_date'] ?? map['graduationDate'] ?? '').toString(),
      leftDate: map['leftDate'] ?? '',
      classId: map['classId'],
      className: map['class'],  // Added className from map
      isSaved: true,
    );
  }

  /// Create a copy of this student with updated fields
  Student copyWith({
    int? id,
    String? studentId,
    int? rollNo,
    String? name,
    String? fatherName,
    String? mobile,
    DateTime? admissionDate,
    String? fee,
    String? status,
    String? struckOffDate,
    String? graduationDate,
    String? leftDate,
    int? classId,
    String? className,  // Added className parameter
    bool? isSaved,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      rollNo: rollNo ?? this.rollNo,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      mobile: mobile ?? this.mobile,
      admissionDate: admissionDate ?? this.admissionDate,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      struckOffDate: struckOffDate ?? this.struckOffDate,
      graduationDate: graduationDate ?? this.graduationDate,
      leftDate: leftDate ?? this.leftDate,
      classId: classId ?? this.classId,
      className: className ?? this.className,  // Added className
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
