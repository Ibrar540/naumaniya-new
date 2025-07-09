// Unified file utilities for both web and mobile platforms
class FileUtils {
  static void downloadPdf(List<int> bytes, String filename) {
    // This will be implemented differently for web vs mobile
    print('PDF download: $filename (${bytes.length} bytes)');
  }

  static void downloadExcel(List<int> bytes, String filename) {
    // This will be implemented differently for web vs mobile
    print('Excel download: $filename (${bytes.length} bytes)');
  }

  static dynamic createFileUploadInput() {
    // This will be implemented differently for web vs mobile
    print('File upload input created');
    return null;
  }

  static dynamic createFileReader() {
    // This will be implemented differently for web vs mobile
    print('File reader created');
    return null;
  }
} 