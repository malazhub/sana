import 'dart:convert';
import 'dart:typed_data';

class DocumentModel {
  final String id;
  final String userId;
  final String guestId;
  final String name;
  final String fileType;
  final String? fileUrl;
  final String? storagePath;
  final DateTime date;
  final Uint8List? bytes;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.guestId,
    required this.name,
    required this.fileType,
    required this.date,
    this.fileUrl,
    this.storagePath,
    this.bytes,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory DocumentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return DocumentModel(
      id: map['id']?.toString() ?? '',
      userId:
          map['user_id']?.toString() ??
          map['userId']?.toString() ??
          '',
      guestId:
          map['guest_id']?.toString() ??
          map['guestId']?.toString() ??
          '',
      name: map['name']?.toString() ?? '',
      fileType:
          map['file_type']?.toString() ??
          map['fileType']?.toString() ??
          'file',
      fileUrl: _nullableString(
        map['file_url'] ??
            map['fileUrl'] ??
            map['path'],
      ),
      storagePath: _nullableString(
        map['storage_path'] ??
            map['storagePath'],
      ),
      date: _parseDate(
        map['date'] ??
            map['upload_date'],
      ),
      bytes: _parseBytes(
        map['bytes_data'] ??
            map['bytes'],
      ),
    );
  }

  // ============================================================
  // LOCAL MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    String bytesData = '';

    if (bytes != null &&
        bytes!.isNotEmpty &&
        bytes!.length <= 300000) {
      bytesData = base64Encode(bytes!);
    }

    return {
      'id': id,
      'user_id': userId,
      'guest_id': guestId,
      'name': name,
      'file_type': fileType,
      'file_url': fileUrl ?? '',
      'storage_path': storagePath ?? '',
      'bytes_data': bytesData,
      'date': date.toIso8601String(),
    };
  }

  // ============================================================
  // SUPABASE MAP
  // ============================================================

  Map<String, dynamic> toSupabaseMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'file_type': fileType,
      'path': fileUrl ?? '',
      'upload_date': date.toIso8601String(),
    };

    /*
     * Guest records belong to the shared guest database.
     *
     * Registered records belong only to their authenticated
     * account.
     *
     * Never send both ownership fields for the same record.
     */
    if (userId.trim().isNotEmpty) {
      map['user_id'] = userId;
      map['guest_id'] = null;
    } else {
      map['user_id'] = null;
      map['guest_id'] =
          guestId.trim().isEmpty
              ? 'guest'
              : guestId.trim();
    }

    return map;
  }

  // ============================================================
  // COPY
  // ============================================================

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? guestId,
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
      guestId: guestId ?? this.guestId,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      date: date ?? this.date,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  // ============================================================
  // PARSING HELPERS
  // ============================================================

  static Uint8List? _parseBytes(
    dynamic rawBytes,
  ) {
    if (rawBytes == null) {
      return null;
    }

    try {
      if (rawBytes is Uint8List) {
        return rawBytes;
      }

      if (rawBytes is List) {
        final values = rawBytes
            .whereType<int>()
            .where(
              (value) =>
                  value >= 0 &&
                  value <= 255,
            )
            .toList();

        if (values.isEmpty) {
          return null;
        }

        return Uint8List.fromList(values);
      }

      final value =
          rawBytes.toString().trim();

      if (value.isEmpty) {
        return null;
      }

      if (value.startsWith('data:')) {
        final data =
            Uri.tryParse(value)?.data;

        if (data != null) {
          final result =
              data.contentAsBytes();

          return result.isEmpty
              ? null
              : result;
        }

        return null;
      }

      final result =
          base64Decode(value);

      return result.isEmpty
          ? null
          : result;
    } catch (_) {
      return null;
    }
  }

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? DateTime.now();
  }

  static String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result =
        value.toString().trim();

    return result.isEmpty
        ? null
        : result;
  }
}