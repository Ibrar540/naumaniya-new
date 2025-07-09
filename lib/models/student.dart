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
  String stuckupDate;
  String graduationDate;
  String leftDate;
  int? classId;
  String? imageUrl; // Cloudinary image URL
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
    this.stuckupDate = '',
    this.graduationDate = '',
    this.leftDate = '',
    this.classId,
    this.imageUrl,
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
      'stuckupDate': stuckupDate,
      'graduationDate': graduationDate,
      'leftDate': leftDate,
      'classId': classId,
      'imageUrl': imageUrl,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    DateTime parseAdmissionDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == 'none') {
        return DateTime.now();
      }
      try {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Student(
      id: map['id'],
      studentId: map['student_id'],
      rollNo: map['roll_no'],
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      mobile: map['mobile'] ?? '',
      admissionDate: parseAdmissionDate(map['admissionDate']),
      fee: map['fee'] ?? '',
      status: (map['status'] ?? '').toString().trim().isEmpty ? 'Active' : map['status'],
      stuckupDate: map['stuckupDate'] ?? '',
      graduationDate: map['graduationDate'] ?? '',
      leftDate: map['leftDate'] ?? '',
      classId: map['classId'],
      imageUrl: map['imageUrl'],
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
    String? stuckupDate,
    String? graduationDate,
    String? leftDate,
    int? classId,
    String? imageUrl,
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
      stuckupDate: stuckupDate ?? this.stuckupDate,
      graduationDate: graduationDate ?? this.graduationDate,
      leftDate: leftDate ?? this.leftDate,
      classId: classId ?? this.classId,
      imageUrl: imageUrl ?? this.imageUrl,
      isSaved: isSaved ?? this.isSaved,
    );
  }
} 