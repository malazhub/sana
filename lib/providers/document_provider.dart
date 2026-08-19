import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document.dart';

class DocumentProvider extends ChangeNotifier {
  static const String _localStorageKey = 'saved_documents_v2';
  static const String _legacyStorageKey = 'saved_documents';
  static const String _storageBucket = 'documents';

  final List<DocumentModel> _documents = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get documents =>
      List.unmodifiable(_documents);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser => _supabase?.auth.currentUser;

  DocumentProvider() {
    loadDocuments();
  }

  // ============================================================
  // LOAD DOCUMENTS
  // ============================================================

  Future<void> loadDocuments() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _clearError();

    _documents.clear();

    try {
      final user = _currentUser;

      if (user == null) {
        await _loadLocalDocuments();
        return;
      }

      final client = _supabase;

      if (client == null) {
        await _loadLocalDocuments();
        return;
      }

      final response = await client
          .from('documents')
          .select()
          .eq('user_id', user.id)
          .order(
            'upload_date',
            ascending: false,
          );

      for (final item in response) {
        try {
          final document = DocumentModel.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (document.id.isEmpty) {
            continue;
          }

          // Never allow another user's document into memory.
          if (document.userId != user.id) {
            continue;
          }

          _documents.add(document);
        } catch (error) {
          debugPrint(
            'Invalid Supabase document: $error',
          );
        }
      }

      await _saveToLocal();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load documents: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to load your documents.',
      );

      // Local cache is only a fallback.
      _documents.clear();
      await _loadLocalDocuments();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ADD / UPDATE DOCUMENT
  // ============================================================

  Future<void> addDocument(
    DocumentModel document,
  ) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to save a document.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    // A document belonging to another user must never be saved.
    if (document.userId.isNotEmpty &&
        document.userId != user.id) {
      throw StateError(
        'This document belongs to another user.',
      );
    }

    _clearError();

    var documentToSave = document.copyWith(
      userId: user.id,
    );

    try {
      if (_shouldUploadToStorage(documentToSave)) {
        documentToSave =
            await _uploadDocumentToStorage(
          documentToSave,
        );
      }

      await client
          .from('documents')
          .upsert(
            documentToSave.toSupabaseMap(),
            onConflict: 'id',
          );

      final index = _documents.indexWhere(
        (item) => item.id == documentToSave.id,
      );

      if (index >= 0) {
        _documents[index] = documentToSave;
      } else {
        _documents.insert(
          0,
          documentToSave,
        );
      }

      await _saveToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to save document: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to save the document.',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> deleteDocument(
    String id,
  ) async {
    final user = _currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to delete a document.',
      );
    }

    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    final index = _documents.indexWhere(
      (document) => document.id == id,
    );

    if (index < 0) {
      return;
    }

    final document = _documents[index];

    if (document.userId != user.id) {
      throw StateError(
        'You cannot delete another user\'s document.',
      );
    }

    _clearError();

    try {
      final storagePath =
          document.storagePath?.trim();

      if (storagePath != null &&
          storagePath.isNotEmpty) {
        try {
          await client.storage
              .from(_storageBucket)
              .remove([
            storagePath,
          ]);
        } catch (error) {
          debugPrint(
            'Failed to remove document file: '
            '$error',
          );

          // Continue with database deletion.
        }
      }

      await client
          .from('documents')
          .delete()
          .eq(
            'id',
            id,
          )
          .eq(
            'user_id',
            user.id,
          );

      _documents.removeAt(index);

      await _saveToLocal();

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to delete document: '
        '$error\n$stackTrace',
      );

      _setError(
        'Unable to delete the document.',
      );

      rethrow;
    }
  }

  // ============================================================
  // SIGNED DOCUMENT URL
  // ============================================================

  Future<String?> getSignedDocumentUrl(
    DocumentModel document, {
    int expiresInSeconds = 300,
  }) async {
    final user = _currentUser;

    if (user == null ||
        document.userId != user.id) {
      return null;
    }

    final path = document.storagePath?.trim();

    if (path == null || path.isEmpty) {
      return document.fileUrl;
    }

    final client = _supabase;

    if (client == null) {
      return document.fileUrl;
    }

    try {
      return await client.storage
          .from(_storageBucket)
          .createSignedUrl(
            path,
            expiresInSeconds,
          );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to create signed document URL: '
        '$error\n$stackTrace',
      );

      // If the document already has a public URL,
      // keep it available as a fallback.
      return document.fileUrl;
    }
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  Future<void> clearLocalDocuments() async {
    _documents.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _localStorageKey,
    );

    await prefs.remove(
      _legacyStorageKey,
    );

    notifyListeners();
  }

  Future<void> _loadLocalDocuments() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final localData =
          prefs.getString(
                _localStorageKey,
              ) ??
              prefs.getString(
                _legacyStorageKey,
              );

      if (localData == null ||
          localData.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(localData);

      if (decoded is! List) {
        return;
      }

      final user = _currentUser;

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final document =
              DocumentModel.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (document.id.isEmpty) {
            continue;
          }

          // If signed in, only load this user's cache.
          if (user != null) {
            if (document.userId.isEmpty ||
                document.userId != user.id) {
              continue;
            }
          }

          final exists = _documents.any(
            (existing) =>
                existing.id == document.id,
          );

          if (!exists) {
            _documents.add(document);
          }
        } catch (error) {
          debugPrint(
            'Invalid local document: '
            '$error',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load local documents: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final user = _currentUser;

      if (user == null) {
        return;
      }

      final prefs =
          await SharedPreferences.getInstance();

      final maps = _documents
          .where(
            (document) =>
                document.userId == user.id,
          )
          .map(
            (document) => document.toMap(),
          )
          .toList();

      await prefs.setString(
        _localStorageKey,
        jsonEncode(maps),
      );
    } catch (error) {
      debugPrint(
        'Failed to cache documents: '
        '$error',
      );
    }
  }

  // ============================================================
  // STORAGE
  // ============================================================

  bool _shouldUploadToStorage(
    DocumentModel document,
  ) {
    final bytes = document.bytes;

    if (bytes == null ||
        bytes.isEmpty) {
      return false;
    }

    final storagePath =
        document.storagePath?.trim();

    if (storagePath != null &&
        storagePath.isNotEmpty) {
      return false;
    }

    return true;
  }

  Future<DocumentModel> _uploadDocumentToStorage(
    DocumentModel document,
  ) async {
    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    final bytes = document.bytes;

    if (bytes == null ||
        bytes.isEmpty) {
      return document;
    }

    final extension =
        _normalizeExtension(
      document.fileType,
    );

    final storagePath =
        '${document.userId}/${document.id}.$extension';

    await client.storage
        .from(_storageBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType:
                _contentTypeForExtension(
              extension,
            ),
            upsert: true,
          ),
        );

    return document.copyWith(
      storagePath: storagePath,
      fileUrl: null,
    );
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // ============================================================
  // FILE TYPES
  // ============================================================

  String _normalizeExtension(
    String fileType,
  ) {
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

  String _contentTypeForExtension(
    String extension,
  ) {
    switch (extension) {
      case 'jpg':
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