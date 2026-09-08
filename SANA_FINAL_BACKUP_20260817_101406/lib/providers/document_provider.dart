import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document.dart';

class DocumentProvider with ChangeNotifier {
  static const String _localStorageKey = 'saved_documents_v2';
  static const String _storageBucket = 'documents';

  final List<DocumentModel> _documents = [];
  bool _isLoading = false;

  List<DocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  DocumentProvider() {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadLocalDocuments();
      await _loadSupabaseDocuments();
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final localData = prefs.getString(_localStorageKey) ??
          prefs.getString('saved_documents');

      if (localData == null || localData.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(localData);

      if (decoded is! List) {
        return;
      }

      for (final item in decoded) {
        try {
          final document = DocumentModel.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (document.id.isEmpty) {
            continue;
          }

          final index = _documents.indexWhere(
            (existing) => existing.id == document.id,
          );

          if (index >= 0) {
            _documents[index] = document;
          } else {
            _documents.add(document);
          }
        } catch (e) {
          debugPrint('Invalid local document: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading local documents: $e');
    }
  }

  Future<void> _loadSupabaseDocuments() async {
    final client = _supabase;

    if (client == null) {
      return;
    }

    try {
      final response = await client
          .from('documents')
          .select()
          .order('date', ascending: false);

      for (final item in response) {
        try {
          final cloudDocument =
              DocumentModel.fromMap(Map<String, dynamic>.from(item));

          if (cloudDocument.id.isEmpty) {
            continue;
          }

          final index = _documents.indexWhere(
            (existing) => existing.id == cloudDocument.id,
          );

          if (index >= 0) {
            final localDocument = _documents[index];

            _documents[index] = cloudDocument.copyWith(
              bytes: cloudDocument.bytes ?? localDocument.bytes,
            );
          } else {
            _documents.add(cloudDocument);
          }
        } catch (e) {
          debugPrint('Error parsing Supabase document: $e');
        }
      }

      await _saveToLocal();
    } catch (e) {
      debugPrint('Failed to load documents from Supabase: $e');
    }
  }

  Future<void> addDocument(DocumentModel doc) async {
    DocumentModel documentToSave = doc;

    try {
      if (_shouldUploadToStorage(doc)) {
        documentToSave = await _uploadDocumentToStorage(doc);
      }

      final index = _documents.indexWhere(
        (existing) => existing.id == documentToSave.id,
      );

      if (index >= 0) {
        _documents[index] = documentToSave;
      } else {
        _documents.add(documentToSave);
      }

      notifyListeners();
      await _saveToLocal();

      final client = _supabase;

      if (client != null) {
        await client.from('documents').upsert(
              documentToSave.toSupabaseMap(),
              onConflict: 'id',
            );
      }
    } catch (e) {
      debugPrint('Failed to save document: $e');

      final index = _documents.indexWhere(
        (existing) => existing.id == documentToSave.id,
      );

      if (index >= 0) {
        _documents.removeAt(index);
        notifyListeners();
        await _saveToLocal();
      }

      rethrow;
    }
  }

  bool _shouldUploadToStorage(DocumentModel doc) {
    if (doc.bytes == null || doc.bytes!.isEmpty) {
      return false;
    }

    if (doc.storagePath != null && doc.storagePath!.trim().isNotEmpty) {
      return false;
    }

    if (doc.fileUrl != null &&
        doc.fileUrl!.trim().isNotEmpty &&
        (doc.fileUrl!.startsWith('http://') ||
            doc.fileUrl!.startsWith('https://'))) {
      return false;
    }

    return true;
  }

  Future<DocumentModel> _uploadDocumentToStorage(
    DocumentModel doc,
  ) async {
    final client = _supabase;

    if (client == null) {
      throw Exception('Supabase is not initialized.');
    }

    final bytes = doc.bytes;

    if (bytes == null || bytes.isEmpty) {
      return doc;
    }

    final extension = _normalizeExtension(doc.fileType);

    final safeId = doc.id.trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : doc.id.trim();

    final storagePath = 'documents/$safeId.$extension';

    await client.storage.from(_storageBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(extension),
            upsert: true,
          ),
        );

    final publicUrl =
        client.storage.from(_storageBucket).getPublicUrl(storagePath);

    return doc.copyWith(
      fileUrl: publicUrl,
      storagePath: storagePath,
    );
  }

  Future<void> deleteDocument(String id) async {
    final index = _documents.indexWhere(
      (doc) => doc.id == id,
    );

    if (index < 0) {
      return;
    }

    final document = _documents[index];

    _documents.removeAt(index);
    notifyListeners();
    await _saveToLocal();

    final client = _supabase;

    if (client == null) {
      return;
    }

    try {
      if (document.storagePath != null &&
          document.storagePath!.trim().isNotEmpty) {
        await client.storage
            .from(_storageBucket)
            .remove([document.storagePath!]);
      }

      await client.from('documents').delete().eq('id', id);
    } catch (e) {
      debugPrint('Failed to delete document from Supabase: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final maps = _documents.map((document) => document.toMap()).toList();

      await prefs.setString(
        _localStorageKey,
        jsonEncode(maps),
      );
    } catch (e) {
      debugPrint('Error saving documents locally: $e');
    }
  }

  String _normalizeExtension(String fileType) {
    switch (fileType.trim().toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return 'jpg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      case 'pdf':
        return 'pdf';
      case 'mp4':
        return 'mp4';
      case 'mov':
        return 'mov';
      case 'avi':
        return 'avi';
      case 'image':
        return 'jpg';
      default:
        return 'bin';
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}
