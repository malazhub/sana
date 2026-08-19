import 'dart:convert';
import 'dart:typed_data';

class DocumentModel {
  final String id;
  final String userId;
  final String name;
  final String fileType;
  final String? fileUrl;
  final String? storagePath;
  final DateTime date;
  final Uint8List? bytes;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.fileType,
    required this.date,
    this.fileUrl,
    this.storagePath,
    this.bytes,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    Uint8List? parsedBytes;

    final rawBytes = map['bytes_data'] ?? map['bytes'];

    try {
      if (rawBytes is Uint8List) {
        parsedBytes = rawBytes;
      } else if (rawBytes is List) {
        parsedBytes = Uint8List.fromList(
          rawBytes.whereType<int>().toList(),
        );
      } else if (rawBytes != null) {
        final value = rawBytes.toString().trim();

        if (value.isNotEmpty) {
          if (value.startsWith('data:')) {
            final data = Uri.parse(value).data;

            if (data != null) {
              parsedBytes = data.contentAsBytes();
            }
          } else {
            parsedBytes = base64Decode(value);
          }
        }
      }
    } catch (_) {
      parsedBytes = null;
    }

    return DocumentModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ??
          map['userId']?.toString() ??
          '',
      name: map['name']?.toString() ?? '',
      fileType: map['file_type']?.toString() ??
          map['fileType']?.toString() ??
          'file',
      fileUrl: _nullableString(
        map['file_url'] ?? map['fileUrl'] ?? map['path'],
      ),
      storagePath: _nullableString(
        map['storage_path'] ?? map['storagePath'],
      ),
      date: DateTime.tryParse(
            map['date']?.toString() ??
                map['upload_date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      bytes: parsedBytes,
    );
  }

  Map<String, dynamic> toMap() {
    String bytesData = '';

    // Keep large files out of SharedPreferences.
    if (bytes != null &&
        bytes!.isNotEmpty &&
        bytes!.length <= 300000) {
      bytesData = base64Encode(bytes!);
    }

    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'file_type': fileType,
      'file_url': fileUrl ?? '',
      'storage_path': storagePath ?? '',
      'bytes_data': bytesData,
      'date': date.toIso8601String(),
    };
  }

  /// Payload matching the Supabase `documents` table.
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'file_type': fileType,
      'path': fileUrl ?? '',
      'upload_date': date.toIso8601String(),
    };
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? fileType,
    String? fileUrl,
    String? storagePath,
    DateTime? date,
    Uint8List? bytes,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      date: date ?? this.date,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}