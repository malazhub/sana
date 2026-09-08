import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document.dart';
import '../services/user_identity_service.dart';

class DocumentProvider extends ChangeNotifier {
  static const String _localStorageKey = 'saved_documents_v2';
  static const String _legacyStorageKey = 'saved_documents';
  static const String _storageBucket = 'documents';

  final List<DocumentModel> _documents = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get documents => List.unmodifiable(_documents);

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
      final client = _supabase;

      if (client == null) {
        await _loadLocalDocuments();
        return;
      }

      final user = _currentUser;

      if (user == null) {
        final guestId = await GuestIdentityService.getGuestId();

        final response = await client
            .from('documents')
            .select()
            .eq('user_id', guestId)
            .isFilter('user_id', null)
            .order(
              'upload_date',
              ascending: false,
            );

        _addDocumentsFromResponse(
          response,
          expectedUserId: null,
          expectedGuestId: guestId,
        );
      } else {
        final response = await client
            .from('documents')
            .select()
            .eq('user_id', user.id)
            .isFilter('user_id', null)
            .order(
              'upload_date',
              ascending: false,
            );

        _addDocumentsFromResponse(
          response,
          expectedUserId: user.id,
          expectedGuestId: null,
        );
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

      _documents.clear();
      await _loadLocalDocuments();
    } finally {
      _setLoading(false);
    }
  }

  void _addDocumentsFromResponse(
    dynamic response, {
    required String? expectedUserId,
    required String? expectedGuestId,
  }) {
    if (response is! List) {
      return;
    }

    for (final item in response) {
      try {
        if (item is! Map) {
          continue;
        }

        final document = DocumentModel.fromMap(
          Map<String, dynamic>.from(item),
        );

        if (document.id.isEmpty) {
          continue;
        }

        if (expectedUserId != null) {
          if (document.userId != expectedUserId ||
              document.guestId.isNotEmpty) {
            continue;
          }
        } else {
          if (document.guestId != expectedGuestId ||
              document.userId.isNotEmpty) {
            continue;
          }
        }

        _documents.add(document);
      } catch (error) {
        debugPrint(
          'Invalid Supabase document: $error',
        );
      }
    }
  }

  // ============================================================
  // ADD / UPDATE DOCUMENT
  // ============================================================

  Future<void> addDocument(
    DocumentModel document,
  ) async {
    final client = _supabase;

    if (client == null) {
      throw StateError(
        'Supabase is not initialized.',
      );
    }

    _clearError();

    final user = _currentUser;

    late DocumentModel documentToSave;

    if (user == null) {
      final guestId = await GuestIdentityService.getGuestId();

      if (document.userId.isNotEmpty) {
        throw StateError(
          'A private user document cannot be saved in guest mode.',
        );
      }

      documentToSave = document.copyWith(
        userId: '',
        guestId: guestId,
      );
    } else {
      if (document.userId.isNotEmpty && document.userId != user.id) {
        throw StateError(
          'This document belongs to another user.',
        );
      }

      documentToSave = document.copyWith(
        userId: user.id,
        guestId: '',
      );
    }

    try {
      if (_shouldUploadToStorage(
        documentToSave,
      )) {
        documentToSave = await _uploadDocumentToStorage(
          documentToSave,
        );
      }

      await client.from('documents').upsert(
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

    final user = _currentUser;

    String guestId = '';

    if (user == null) {
      guestId = await GuestIdentityService.getGuestId();

      if (document.guestId != guestId || document.userId.isNotEmpty) {
        throw StateError(
          'You cannot delete another user\'s document.',
        );
      }
    } else {
      if (document.userId != user.id || document.guestId.isNotEmpty) {
        throw StateError(
          'You cannot delete another user\'s document.',
        );
      }
    }

    _clearError();

    try {
      final storagePath = document.storagePath?.trim();

      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await client.storage.from(_storageBucket).remove([
            storagePath,
          ]);
        } catch (error) {
          debugPrint(
            'Failed to remove document file: '
            '$error',
          );
        }
      }

      var query = client.from('documents').delete().eq(
            'id',
            id,
          );

      if (user == null) {
        query = query
            .eq(
              'user_id',
              guestId,
            )
            .isFilter(
              'user_id',
              null,
            );
      } else {
        query = query
            .eq(
              'user_id',
              user.id,
            )
            .isFilter(
              'user_id',
              null,
            );
      }

      await query;

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

    if (user == null) {
      final guestId = await GuestIdentityService.getGuestId();

      if (document.guestId != guestId || document.userId.isNotEmpty) {
        return null;
      }
    } else {
      if (document.userId != user.id || document.guestId.isNotEmpty) {
        return null;
      }
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
      return await client.storage.from(_storageBucket).createSignedUrl(
            path,
            expiresInSeconds,
          );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to create signed document URL: '
        '$error\n$stackTrace',
      );

      return document.fileUrl;
    }
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  Future<void> clearLocalDocuments() async {
    _documents.clear();

    final prefs = await SharedPreferences.getInstance();

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
      final prefs = await SharedPreferences.getInstance();

      final localData = prefs.getString(
            _localStorageKey,
          ) ??
          prefs.getString(
            _legacyStorageKey,
          );

      if (localData == null || localData.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(localData);

      if (decoded is! List) {
        return;
      }

      final user = _currentUser;

      String? guestId;

      if (user == null) {
        guestId = await GuestIdentityService.getGuestId();
      }

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final document = DocumentModel.fromMap(
            Map<String, dynamic>.from(item),
          );

          if (document.id.isEmpty) {
            continue;
          }

          if (user != null) {
            if (document.userId != user.id || document.guestId.isNotEmpty) {
              continue;
            }
          } else {
            if (document.guestId != guestId || document.userId.isNotEmpty) {
              continue;
            }
          }

          final exists = _documents.any(
            (existing) => existing.id == document.id,
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
      final prefs = await SharedPreferences.getInstance();

      final maps = _documents
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

    if (bytes == null || bytes.isEmpty) {
      return false;
    }

    final storagePath = document.storagePath?.trim();

    if (storagePath != null && storagePath.isNotEmpty) {
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

    if (bytes == null || bytes.isEmpty) {
      return document;
    }

    final extension = _normalizeExtension(
      document.fileType,
    );

    final owner = document.userId.trim().isNotEmpty
        ? document.userId.trim()
        : document.guestId.trim();

    if (owner.isEmpty) {
      throw StateError(
        'Document ownership is required.',
      );
    }

    final storagePath = '$owner/${document.id}.$extension';

    await client.storage.from(_storageBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(
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
