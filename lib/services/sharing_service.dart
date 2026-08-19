//import 'dart:convert';
//import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static String _value(dynamic object, String key) {
    if (object == null) {
      return '';
    }

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
      '📋 Medical Summary'
      '${name != null && name.isNotEmpty ? ': $name' : ''}',
    );

    final now = DateTime.now();

    buffer.writeln(
      'Date: ${now.day}/${now.month}/${now.year}',
    );

    buffer.writeln(
      '-----------------------------------',
    );

    if (medications != null &&
        medications.isNotEmpty) {
      buffer.writeln(
        '\nMEDICATIONS (${medications.length}):',
      );

      for (final medication in medications) {
        final medicationName =
            _value(medication, 'name');

        final dosage =
            _value(medication, 'dosage');

        final repeat =
            _value(medication, 'repeatType');

        buffer.writeln(
          '- $medicationName'
          '${dosage.isNotEmpty ? ' | Dosage: $dosage' : ''}'
          '${repeat.isNotEmpty ? ' ($repeat)' : ''}',
        );
      }
    }

    if (doctors != null && doctors.isNotEmpty) {
      buffer.writeln(
        '\nDOCTORS (${doctors.length}):',
      );

      for (final doctor in doctors) {
        final doctorName =
            _value(doctor, 'name');

        final specialty =
            _value(doctor, 'specialty');

        final phone =
            _value(doctor, 'phone');

        buffer.writeln(
          '- $doctorName'
          '${specialty.isNotEmpty ? ' ($specialty)' : ''}'
          '${phone.isNotEmpty ? ' | Phone: $phone' : ''}',
        );
      }
    }

    if (pharmacies != null &&
        pharmacies.isNotEmpty) {
      buffer.writeln(
        '\nPHARMACIES (${pharmacies.length}):',
      );

      for (final pharmacy in pharmacies) {
        final pharmacyName =
            _value(pharmacy, 'name');

        final address =
            _value(pharmacy, 'address');

        final phone =
            _value(pharmacy, 'phone');

        buffer.writeln(
          '- $pharmacyName'
          '${address.isNotEmpty ? ' | Address: $address' : ''}'
          '${phone.isNotEmpty ? ' | Phone: $phone' : ''}',
        );
      }
    }

    if (history != null && history.isNotEmpty) {
      buffer.writeln(
        '\nMEDICATION HISTORY (${history.length}):',
      );

      for (final item in history) {
        final description =
            _value(item, 'name');

        buffer.writeln(
          '- ${description.isNotEmpty ? description : item}',
        );
      }
    }

    if (documents != null &&
        documents.isNotEmpty) {
      buffer.writeln(
        '\nDOCUMENTS (${documents.length}):',
      );

      for (final document in documents) {
        final documentName =
            _value(document, 'name');

        buffer.writeln(
          '- ${documentName.isNotEmpty ? documentName : document}',
        );
      }
    }

    if (insuranceCards != null &&
        insuranceCards.isNotEmpty) {
      buffer.writeln(
        '\nINSURANCE CARDS (${insuranceCards.length}):',
      );

      for (final card in insuranceCards) {
        final cardName =
            _value(card, 'name');

        buffer.writeln(
          '- ${cardName.isNotEmpty ? cardName : card}',
        );
      }
    }

    return buffer.toString();
  }

  

  // ============================================================
  // MAIN SHARE API
  // ============================================================

  static Future<void> shareRecord({
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
        subject:
            name ?? 'Medical Summary',
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
        margin:
            const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                'Medical Record Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
          );

          if (name != null &&
              name.isNotEmpty) {
            widgets.add(
              pw.Text(
                'Patient / Record: $name',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            );
          }

          final now = DateTime.now();

          widgets.add(
            pw.Text(
              'Date: ${now.day}/${now.month}/${now.year}',
            ),
          );

          widgets.add(
            pw.SizedBox(height: 10),
          );

          widgets.add(
            pw.Divider(),
          );

          void addSection(
            String title,
            List<dynamic>? items,
            String Function(dynamic) formatter,
          ) {
            if (items == null ||
                items.isEmpty) {
              return;
            }

            widgets.add(
              pw.SizedBox(height: 10),
            );

            widgets.add(
              pw.Text(
                '$title (${items.length})',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight:
                      pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
            );

            widgets.add(
              pw.SizedBox(height: 6),
            );

            for (final item in items) {
              widgets.add(
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: pw.Text(
                    '• ${formatter(item)}',
                    style:
                        const pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }
          }

          addSection(
            'MEDICATIONS',
            medications,
            (medication) {
              final medicationName =
                  _value(
                medication,
                'name',
              );

              final dosage =
                  _value(
                medication,
                'dosage',
              );

              final repeat =
                  _value(
                medication,
                'repeatType',
              );

              return '$medicationName'
                  '${dosage.isNotEmpty ? ' | Dosage: $dosage' : ''}'
                  '${repeat.isNotEmpty ? ' ($repeat)' : ''}';
            },
          );

          addSection(
            'DOCTORS',
            doctors,
            (doctor) {
              final doctorName =
                  _value(
                doctor,
                'name',
              );

              final specialty =
                  _value(
                doctor,
                'specialty',
              );

              final phone =
                  _value(
                doctor,
                'phone',
              );

              return '$doctorName'
                  '${specialty.isNotEmpty ? ' ($specialty)' : ''}'
                  '${phone.isNotEmpty ? ' | Phone: $phone' : ''}';
            },
          );

          addSection(
            'PHARMACIES',
            pharmacies,
            (pharmacy) {
              final pharmacyName =
                  _value(
                pharmacy,
                'name',
              );

              final address =
                  _value(
                pharmacy,
                'address',
              );

              final phone =
                  _value(
                pharmacy,
                'phone',
              );

              return '$pharmacyName'
                  '${address.isNotEmpty ? ' | Address: $address' : ''}'
                  '${phone.isNotEmpty ? ' | Phone: $phone' : ''}';
            },
          );

          addSection(
            'MEDICATION HISTORY',
            history,
            (item) {
              final value =
                  _value(item, 'name');

              return value.isNotEmpty
                  ? value
                  : item.toString();
            },
          );

          addSection(
            'DOCUMENTS',
            documents,
            (item) {
              final value =
                  _value(item, 'name');

              return value.isNotEmpty
                  ? value
                  : item.toString();
            },
          );

          addSection(
            'INSURANCE CARDS',
            insuranceCards,
            (item) {
              final value =
                  _value(item, 'name');

              return value.isNotEmpty
                  ? value
                  : item.toString();
            },
          );

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'medical_report.pdf',
    );
  }
}