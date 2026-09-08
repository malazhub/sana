import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static String _value(dynamic object, String key) {
    if (object == null) return '';

    if (object is Map) {
      final value = object[key];
      return value?.toString() ?? '';
    }

    try {
      switch (key) {
        case 'name':
          return object.name?.toString() ?? '';
        case 'dosage':
          return object.dosage?.toString() ?? '';
        case 'repeatType':
          return object.repeatType?.toString() ?? '';
        case 'specialty':
          return object.specialty?.toString() ?? '';
        case 'phone':
          return object.phone?.toString() ?? '';
        case 'address':
          return object.address?.toString() ?? '';
        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  static String _generateTextSummary({
    String? name,
    List<dynamic>? medications,
    List<dynamic>? doctors,
    List<dynamic>? pharmacies,
    List<dynamic>? history,
    List<dynamic>? documents,
    List<dynamic>? insuranceCards,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      '📋 Medical Summary${name != null && name.isNotEmpty ? ': $name' : ''}',
    );
    final now = DateTime.now();
    buffer.writeln('Date: ${now.day}/${now.month}/${now.year}');
    buffer.writeln('-----------------------------------');

    if (medications != null && medications.isNotEmpty) {
      buffer.writeln('\nMEDICATIONS (${medications.length}):');
      for (final m in medications) {
        final medName = _value(m, 'name');
        final dosage = _value(m, 'dosage');
        final repeat = _value(m, 'repeatType');

        buffer.writeln(
          '- $medName'
          '${dosage.isNotEmpty ? ' | Dosage: $dosage' : ''}'
          '${repeat.isNotEmpty ? ' ($repeat)' : ''}',
        );
      }
    }

    if (doctors != null && doctors.isNotEmpty) {
      buffer.writeln('\nDOCTORS (${doctors.length}):');
      for (final d in doctors) {
        final doctorName = _value(d, 'name');
        final specialty = _value(d, 'specialty');
        final phone = _value(d, 'phone');

        buffer.writeln(
          '- $doctorName'
          '${specialty.isNotEmpty ? ' ($specialty)' : ''}'
          '${phone.isNotEmpty ? ' | Phone: $phone' : ''}',
        );
      }
    }

    if (pharmacies != null && pharmacies.isNotEmpty) {
      buffer.writeln('\nPHARMACIES (${pharmacies.length}):');
      for (final p in pharmacies) {
        final pharmacyName = _value(p, 'name');
        final address = _value(p, 'address');
        final phone = _value(p, 'phone');

        buffer.writeln(
          '- $pharmacyName'
          '${address.isNotEmpty ? ' | Address: $address' : ''}'
          '${phone.isNotEmpty ? ' | Phone: $phone' : ''}',
        );
      }
    }

    if (history != null && history.isNotEmpty) {
      buffer.writeln('\nMEDICATION HISTORY (${history.length}):');
      for (final h in history) {
        final description = _value(h, 'name');
        if (description.isNotEmpty) {
          buffer.writeln('- $description');
        } else {
          buffer.writeln('- ${h.toString()}');
        }
      }
    }

    if (documents != null && documents.isNotEmpty) {
      buffer.writeln('\nDOCUMENTS (${documents.length}):');
      for (final d in documents) {
        final documentName = _value(d, 'name');
        buffer.writeln(
          '- ${documentName.isNotEmpty ? documentName : d.toString()}',
        );
      }
    }

    if (insuranceCards != null && insuranceCards.isNotEmpty) {
      buffer.writeln('\nINSURANCE CARDS (${insuranceCards.length}):');
      for (final card in insuranceCards) {
        final cardName = _value(card, 'name');
        buffer.writeln(
          '- ${cardName.isNotEmpty ? cardName : card.toString()}',
        );
      }
    }

    return buffer.toString();
  }

  static Uint8List? _resolveImageBytes(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return null;

    try {
      if (clean.startsWith('data:image')) {
        return Uri.parse(clean).data?.contentAsBytes();
      }

      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  static Future<void> shareMedications({
    String? name,
    List<dynamic>? medications,
    List<dynamic>? doctors,
    List<dynamic>? pharmacies,
    List<dynamic>? history,
    List<dynamic>? documents,
    List<dynamic>? insuranceCards,
  }) async {
    final summary = _generateTextSummary(
      name: name,
      medications: medications,
      doctors: doctors,
      pharmacies: pharmacies,
      history: history,
      documents: documents,
      insuranceCards: insuranceCards,
    );

    await SharePlus.instance.share(
      ShareParams(
        text: summary,
        subject: name ?? 'Medical Summary',
      ),
    );
  }

  static Future<void> shareTextSummary({
    String? name,
    List<dynamic>? medications,
    List<dynamic>? doctors,
    List<dynamic>? pharmacies,
    List<dynamic>? history,
    List<dynamic>? documents,
    List<dynamic>? insuranceCards,
  }) async {
    await shareMedications(
      name: name,
      medications: medications,
      doctors: doctors,
      pharmacies: pharmacies,
      history: history,
      documents: documents,
      insuranceCards: insuranceCards,
    );
  }

  static Future<void> generateAndSharePdf({
    String? name,
    List<dynamic>? medications,
    List<dynamic>? doctors,
    List<dynamic>? pharmacies,
    List<dynamic>? history,
    List<dynamic>? documents,
    List<dynamic>? insuranceCards,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                'Medical Record Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          if (name != null && name.isNotEmpty) {
            widgets.add(
              pw.Text(
                'Patient / Record: $name',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }

          final now = DateTime.now();
          widgets.add(
            pw.Text('Date: ${now.day}/${now.month}/${now.year}'),
          );
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Divider());

          void addSection(
            String title,
            List<dynamic>? items,
            String Function(dynamic) formatter,
          ) {
            if (items == null || items.isEmpty) return;

            widgets.add(pw.SizedBox(height: 10));
            widgets.add(
              pw.Text(
                '$title (${items.length})',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));

            for (final item in items) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    '• ${formatter(item)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              );
            }
          }

          addSection(
            'MEDICATIONS',
            medications,
            (m) {
              final medName = _value(m, 'name');
              final dosage = _value(m, 'dosage');
              final repeat = _value(m, 'repeatType');

              return '$medName'
                  '${dosage.isNotEmpty ? ' | Dosage: $dosage' : ''}'
                  '${repeat.isNotEmpty ? ' ($repeat)' : ''}';
            },
          );

          addSection(
            'DOCTORS',
            doctors,
            (d) {
              final doctorName = _value(d, 'name');
              final specialty = _value(d, 'specialty');
              final phone = _value(d, 'phone');

              return '$doctorName'
                  '${specialty.isNotEmpty ? ' ($specialty)' : ''}'
                  '${phone.isNotEmpty ? ' | Phone: $phone' : ''}';
            },
          );

          addSection(
            'PHARMACIES',
            pharmacies,
            (p) {
              final pharmacyName = _value(p, 'name');
              final address = _value(p, 'address');
              final phone = _value(p, 'phone');

              return '$pharmacyName'
                  '${address.isNotEmpty ? ' | Address: $address' : ''}'
                  '${phone.isNotEmpty ? ' | Phone: $phone' : ''}';
            },
          );

          addSection(
            'MEDICATION HISTORY',
            history,
            (h) =>
                _value(h, 'name').isNotEmpty ? _value(h, 'name') : h.toString(),
          );

          addSection(
            'DOCUMENTS',
            documents,
            (d) =>
                _value(d, 'name').isNotEmpty ? _value(d, 'name') : d.toString(),
          );

          addSection(
            'INSURANCE CARDS',
            insuranceCards,
            (c) =>
                _value(c, 'name').isNotEmpty ? _value(c, 'name') : c.toString(),
          );

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'medical_report.pdf',
    );
  }
}
