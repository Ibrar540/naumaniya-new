import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileUtils {
  static Future<void> downloadPdf(List<int> bytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error saving PDF: $e');
    }
  }

  static Future<void> downloadExcel(List<int> bytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error saving Excel: $e');
    }
  }

  static dynamic createFileUploadInput() {
    return null;
  }

  static dynamic createFileReader() {
    return null;
  }
}
