import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/localization/app_localization.dart';

class ExportHelper {
  static String formatDate(dynamic date) {
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
    } else if (date is DateTime) {
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    } else {
      return date.toString();
    }
  }

  /// PDF
  static Future<void> exportToPDF(BuildContext context, List<Map<String, dynamic>> data) async {
    final loc = AppLocalizations.of(context)!;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(loc.transactionReport, style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              context: context,
              headers: [
                loc.date,
                loc.type,
                loc.category,
                loc.amount,
                loc.description,
              ],
              data: data.map((tx) {
                return [
                  formatDate(tx['date']),
                  tx['type'],
                  tx['category'],
                  '₸ ${tx['amount'].toStringAsFixed(0)}',
                  tx['description'] ?? '',
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/transactions.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  /// CSV
  static Future<void> exportToCSV(BuildContext context, List<Map<String, dynamic>> data) async {
    final loc = AppLocalizations.of(context)!;

    List<List<String>> csvData = [
      [loc.date, loc.type, loc.category, loc.amount, loc.description],
      ...data.map((tx) => [
            formatDate(tx['date']),
            tx['type'],
            tx['category'],
            tx['amount'].toStringAsFixed(0),
            tx['description'] ?? '',
          ]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/transactions.csv");
    await file.writeAsString(csv);
    await OpenFile.open(file.path);
  }

  /// Excel
  static Future<void> exportToExcel(BuildContext context, List<Map<String, dynamic>> data) async {
    final loc = AppLocalizations.of(context)!;
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];

    sheet.appendRow([
      TextCellValue(loc.date),
      TextCellValue(loc.type),
      TextCellValue(loc.category),
      TextCellValue(loc.amount),
      TextCellValue(loc.description),
    ]);

    for (final tx in data) {
      sheet.appendRow([
        TextCellValue(formatDate(tx['date'])),
        TextCellValue(tx['type']),
        TextCellValue(tx['category']),
        DoubleCellValue((tx['amount'] as num).toDouble()),
        TextCellValue(tx['description'] ?? ''),
      ]);
    }

    final bytes = excel.save();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/transactions.xlsx");
    await file.writeAsBytes(bytes!);
    await OpenFile.open(file.path);
  }
}
