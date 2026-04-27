import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/holiday.dart';

PdfColor _holidayPdfColor(String type) {
  switch (type) {
    case 'federal':
      return const PdfColor.fromInt(0xFFEF4444);
    case 'summer_break':
      return const PdfColor.fromInt(0xFFF59E0B);
    case 'spring_break':
      return const PdfColor.fromInt(0xFF10B981);
    case 'winter_break':
      return const PdfColor.fromInt(0xFF3B82F6);
    case 'teacher_workday':
      return const PdfColor.fromInt(0xFF8B5CF6);
    default:
      return const PdfColor.fromInt(0xFF6366F1);
  }
}

Future<Uint8List> generateSchoolYearPdf(
    List<Holiday> holidays, int schoolYear) async {
  final pdf = pw.Document();

  final schoolYearMonths = <DateTime>[];
  for (int m = 8; m <= 12; m++) {
    schoolYearMonths.add(DateTime(schoolYear - 1, m));
  }
  for (int m = 1; m <= 7; m++) {
    schoolYearMonths.add(DateTime(schoolYear, m));
  }

  final holidayDates = <String, Holiday>{};
  for (final h in holidays) {
    final s = DateTime.tryParse(h.startDate);
    final e = DateTime.tryParse(h.endDate);
    if (s == null || e == null) continue;
    for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      holidayDates[key] = h;
    }
  }

  final usedTypes = <String>{};
  for (final h in holidays) {
    usedTypes.add(h.type);
  }

  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  const dayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  pw.Widget buildMiniMonth(DateTime monthDate) {
    final year = monthDate.year;
    final month = monthDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    final rows = <pw.TableRow>[];

    rows.add(pw.TableRow(
      children: dayHeaders
          .map((d) => pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(1),
                child: pw.Text(d,
                    style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700)),
              ))
          .toList(),
    ));

    int dayCounter = 1;
    for (int week = 0; week < 6; week++) {
      if (dayCounter > daysInMonth) break;
      final cells = <pw.Widget>[];
      for (int col = 0; col < 7; col++) {
        final idx = week * 7 + col;
        if (idx < firstWeekday || dayCounter > daysInMonth) {
          cells.add(pw.Container(height: 11));
        } else {
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${dayCounter.toString().padLeft(2, '0')}';
          final holiday = holidayDates[dateStr];
          final bg = holiday != null
              ? _holidayPdfColor(holiday.type).shade(0.85)
              : PdfColors.white;
          final textColor =
              holiday != null ? _holidayPdfColor(holiday.type) : PdfColors.grey800;
          cells.add(pw.Container(
            height: 11,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: pw.BorderRadius.circular(1.5),
            ),
            child: pw.Text('$dayCounter',
                style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: holiday != null
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                    color: textColor)),
          ));
          dayCounter++;
        }
      }
      rows.add(pw.TableRow(children: cells));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF2E6B4F),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Center(
              child: pw.Text('${months[month]} $year',
                  style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Table(children: rows),
        ],
      ),
    );
  }

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(24),
    build: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'School Year ${schoolYear - 1}–$schoolYear Holiday Calendar',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1A2E22)),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (row) {
                return pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: List.generate(3, (col) {
                      final idx = row * 3 + col;
                      return pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: buildMiniMonth(schoolYearMonths[idx]),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: usedTypes.map((t) {
              return pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 6),
                child: pw.Row(children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: _holidayPdfColor(t).shade(0.85),
                      border: pw.Border.all(color: _holidayPdfColor(t), width: 0.5),
                      borderRadius: pw.BorderRadius.circular(1.5),
                    ),
                  ),
                  pw.SizedBox(width: 3),
                  pw.Text(Holiday.typeLabels[t] ?? t,
                      style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                ]),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Generated on ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey500),
            ),
          ),
        ],
      );
    },
  ));

  return pdf.save();
}
