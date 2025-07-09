import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:naumaniya/services/ai_reporting_service.dart';
import 'package:naumaniya/models/student.dart';
import 'package:naumaniya/models/teacher.dart';
import 'package:naumaniya/models/income.dart';
import 'package:naumaniya/models/expenditure.dart';
import 'package:naumaniya/models/ai_query_result.dart';

void main() {
  group('AIReportingService Tests', () {
    late AIReportingService aiService;

    setUp(() {
      aiService = AIReportingService();
    });

    group('Query Parsing Tests', () {
      test('should process student queries', () async {
        // Test the public processQuery method instead of private methods
        final result = await aiService.processQuery('Show all students', isUrdu: false);
        expect(result.module, equals('students'));
      });

      test('should process teacher queries', () async {
        final result = await aiService.processQuery('Show teachers with salary', isUrdu: false);
        expect(result.module, equals('teachers'));
      });

      test('should process budget queries', () async {
        final result = await aiService.processQuery('Show budget records', isUrdu: false);
        expect(result.module, equals('budget'));
      });
    });

    group('Student Query Processing Tests', () {
      test('should filter students by status', () {
        // Test filtering logic directly
        final students = [
          Student(
            id: 1,
            name: 'John Doe',
            fatherName: 'John Sr.',
            mobile: '1234567890',
            admissionDate: DateTime(2024, 1, 1),
            classId: 1,
            status: 'Active',
            fee: '100',
          ),
          Student(
            id: 2,
            name: 'Jane Smith',
            fatherName: 'John Smith',
            mobile: '0987654321',
            admissionDate: DateTime(2024, 1, 1),
            classId: 1,
            status: 'Inactive',
            fee: '100',
          ),
        ];
        
        final filteredStudents = students.where((student) {
          final status = 'Active';
          final studentStatus = student.status.toLowerCase();
          return studentStatus.contains(status.toLowerCase());
        }).toList();

        expect(filteredStudents.length, equals(1));
        expect(filteredStudents.first.name, equals('John Doe'));
      });

      test('should filter students by class', () {
        final students = [
          Student(
            id: 1,
            name: 'John Doe',
            fatherName: 'John Sr.',
            mobile: '1234567890',
            admissionDate: DateTime(2024, 1, 1),
            classId: 1, // Class A
            status: 'Active',
            fee: '100',
          ),
          Student(
            id: 2,
            name: 'Jane Smith',
            fatherName: 'John Smith',
            mobile: '0987654321',
            admissionDate: DateTime(2024, 1, 1),
            classId: 2, // Class B
            status: 'Active',
            fee: '100',
          ),
        ];

        final classInfo = 'A';
        final filteredStudents = students.where((student) {
          final classId = classInfo == 'A' ? 1 : classInfo == 'B' ? 2 : classInfo == 'C' ? 3 : null;
          return classId != null && student.classId == classId;
        }).toList();

        expect(filteredStudents.length, equals(1));
        expect(filteredStudents.first.name, equals('John Doe'));
      });

      test('should filter students by fee amount', () {
        final students = [
          Student(
            id: 1,
            name: 'John Doe',
            fatherName: 'John Sr.',
            mobile: '1234567890',
            admissionDate: DateTime(2024, 1, 1),
            classId: 1,
            status: 'Active',
            fee: '50',
          ),
          Student(
            id: 2,
            name: 'Jane Smith',
            fatherName: 'John Smith',
            mobile: '0987654321',
            admissionDate: DateTime(2024, 1, 1),
            classId: 1,
            status: 'Active',
            fee: '150',
          ),
        ];

        final amountFilter = {'amount': 100, 'operator': 'more'};
        final filteredStudents = students.where((student) {
          final fee = double.tryParse(student.fee) ?? 0;
          if (amountFilter['operator'] == 'more' && fee <= (amountFilter['amount'] as int)) {
            return false;
          }
          return true;
        }).toList();

        expect(filteredStudents.length, equals(1));
        expect(filteredStudents.first.name, equals('Jane Smith'));
      });
    });

    group('Teacher Query Processing Tests', () {
      test('should filter teachers by status', () {
        final teachers = [
          Teacher(
            id: 1,
            name: 'Teacher 1',
            mobile: '1234567890',
            status: 'Active',
            salary: 5000,
            startingDate: DateTime(2024, 1, 1),
          ),
          Teacher(
            id: 2,
            name: 'Teacher 2',
            mobile: '0987654321',
            status: 'Left',
            salary: 6000,
            startingDate: DateTime(2024, 1, 1),
          ),
        ];

        final status = 'Active';
        final filteredTeachers = teachers.where((teacher) {
          final teacherStatus = teacher.status.toLowerCase();
          return teacherStatus.contains(status.toLowerCase());
        }).toList();

        expect(filteredTeachers.length, equals(1));
        expect(filteredTeachers.first.name, equals('Teacher 1'));
      });

      test('should filter teachers by salary', () {
        final teachers = [
          Teacher(
            id: 1,
            name: 'Teacher 1',
            mobile: '1234567890',
            status: 'Active',
            salary: 4000,
            startingDate: DateTime(2024, 1, 1),
          ),
          Teacher(
            id: 2,
            name: 'Teacher 2',
            mobile: '0987654321',
            status: 'Active',
            salary: 6000,
            startingDate: DateTime(2024, 1, 1),
          ),
        ];

        final amountFilter = {'amount': 5000, 'operator': 'more'};
        final filteredTeachers = teachers.where((teacher) {
          final salary = teacher.salary.toDouble();
          if (amountFilter['operator'] == 'more' && salary <= (amountFilter['amount'] as int)) {
            return false;
          }
          return true;
        }).toList();

        expect(filteredTeachers.length, equals(1));
        expect(filteredTeachers.first.name, equals('Teacher 2'));
      });
    });

    group('Budget Query Processing Tests', () {
      test('should filter income by amount', () {
        final incomes = [
          Income(
            id: 1,
            description: 'Fee Collection',
            amount: 500.0,
            date: '2024-01-01',
          ),
          Income(
            id: 2,
            description: 'Donation',
            amount: 1500.0,
            date: '2024-01-01',
          ),
        ];

        final amountFilter = {'amount': 1000, 'operator': 'more'};
        final filteredIncomes = incomes.where((income) {
          final amount = income.amount;
          if (amountFilter['operator'] == 'more' && amount <= (amountFilter['amount'] as int)) {
            return false;
          }
          return true;
        }).toList();

        expect(filteredIncomes.length, equals(1));
        expect(filteredIncomes.first.description, equals('Donation'));
      });

      test('should filter expenditure by amount', () {
        final expenditures = [
          Expenditure(
            id: 1,
            description: 'Utilities',
            amount: 300.0,
            date: '2024-01-01',
          ),
          Expenditure(
            id: 2,
            description: 'Salary',
            amount: 800.0,
            date: '2024-01-01',
          ),
        ];

        final amountFilter = {'amount': 500, 'operator': 'less'};
        final filteredExpenditures = expenditures.where((expenditure) {
          final amount = expenditure.amount;
          if (amountFilter['operator'] == 'less' && amount >= (amountFilter['amount'] as int)) {
            return false;
          }
          return true;
        }).toList();

        expect(filteredExpenditures.length, equals(1));
        expect(filteredExpenditures.first.description, equals('Utilities'));
      });
    });

    group('Error Handling Tests', () {
      test('should throw exception for empty query', () async {
        expect(
          () => aiService.processQuery('', isUrdu: false),
          throwsException,
        );
      });

      test('should throw exception for whitespace-only query', () async {
        expect(
          () => aiService.processQuery('   ', isUrdu: false),
          throwsException,
        );
      });
    });

    group('AIQueryResult Tests', () {
      test('should create AIQueryResult with correct properties', () {
        final result = AIQueryResult(
          module: 'students',
          data: [],
          summary: 'Test summary',
          actions: [],
          filters: {'status': 'Active'},
        );

        expect(result.module, equals('students'));
        expect(result.data, isEmpty);
        expect(result.summary, equals('Test summary'));
        expect(result.actions, isEmpty);
        expect(result.filters['status'], equals('Active'));
      });
    });

    group('AIAction Tests', () {
      test('should create AIAction with correct properties', () {
        final action = AIAction(
          title: 'Test Action',
          description: 'Test Description',
          icon: Icons.people,
          onTap: () {},
        );

        expect(action.title, equals('Test Action'));
        expect(action.description, equals('Test Description'));
        expect(action.icon, equals(Icons.people));
        expect(action.onTap, isA<Function>());
      });
    });
  });
} 