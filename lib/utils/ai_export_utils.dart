import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AIExportUtils {
  /// Export AI response to PDF
  static Future<String?> exportToPDF(String content, Map<String, dynamic>? data) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'AI Assistant Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Content
              pw.Text(
                content,
                style: const pw.TextStyle(fontSize: 12),
              ),
              
              // Data section if available
              if (data != null) ...[
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Query Details:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDataTable(data),
              ],
              
              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Naumaniya Management System',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      // Save to downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/ai_report_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return null;
    }
  }

  /// Build data table for PDF
  static pw.Widget _buildDataTable(Map<String, dynamic> data) {
    final rows = <pw.TableRow>[];
    
    // Add key-value pairs as table rows
    data.forEach((key, value) {
      if (value != null && key != 'message' && key != 'success') {
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  _formatKey(key),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(value.toString()),
              ),
            ],
          ),
        );
      }
    });

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: rows,
    );
  }

  /// Format key for display
  static String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Print AI response
  static Future<void> printReport(String content, Map<String, dynamic>? data) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          final pdf = pw.Document();
          
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AI Assistant Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text(content),
                  if (data != null) ...[
                    pw.SizedBox(height: 20),
                    pw.Divider(),
                    pw.Text(
                      'Query Details:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    _buildDataTable(data),
                  ],
                ],
              ),
            ),
          );
          
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error printing report: $e');
      rethrow;
    }
  }

  /// Share report (for mobile)
  static Future<void> shareReport(String content, Map<String, dynamic>? data) async {
    try {
      final pdfPath = await exportToPDF(content, data);
      if (pdfPath != null) {
        await Printing.sharePdf(
          bytes: await File(pdfPath).readAsBytes(),
          filename: 'ai_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
    } catch (e) {
      debugPrint('Error sharing report: $e');
      rethrow;
    }
  }
}
