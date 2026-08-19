import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document.dart';
import '../providers/document_provider.dart';
import '../providers/language_provider.dart';
import '../services/sharing_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _safeLoadDocs(context.read<DocumentProvider>());
    });
  }

  Future<void> _safeLoadDocs(DocumentProvider provider) async {
    try {
      await provider.loadDocuments();
    } catch (e) {
      debugPrint('Error loading documents: $e');
    }
  }

  bool _getIsLoading(DocumentProvider provider) {
    return provider.isLoading;
  }

  String _tr(LanguageProvider language, String key) {
    final code = language.locale.languageCode;

    switch (key) {
      case 'documents_title':
        if (code == 'ar') return 'المستندات';
        if (code == 'es') return 'Documentos Médicos';
        if (code == 'fr') return 'Documents Médicaux';
        if (code == 'de') return 'Dokumente';
        if (code == 'tr') return 'Belgeler';
        if (code == 'hi') return 'दस्तावेज़';
        if (code == 'zh') return '文档';
        return 'Medical Documents';

      case 'delete_document_confirm':
        if (code == 'ar') return 'هل أنت متأكد من حذف المستند؟';
        if (code == 'es') {
          return '¿Estás seguro de eliminar este documento?';
        }
        if (code == 'fr') {
          return 'Voulez-vous vraiment supprimer ce document ?';
        }
        if (code == 'de') {
          return 'Möchten Sie dieses Dokument wirklich löschen?';
        }
        if (code == 'tr') {
          return 'Bu belgeyi silmek istediğinizden emin misiniz?';
        }
        if (code == 'hi') {
          return 'क्या आप इस दस्तावेज़ को हटाना चाहते हैं?';
        }
        if (code == 'zh') return '您确定要删除此文档吗？';
        return 'Are you sure you want to delete this document?';

      case 'cancel':
        if (code == 'ar') return 'إلغاء';
        if (code == 'es') return 'Cancelar';
        if (code == 'fr') return 'Annuler';
        if (code == 'de') return 'Abbrechen';
        if (code == 'tr') return 'İptal';
        if (code == 'hi') return 'रद्द करें';
        if (code == 'zh') return '取消';
        return 'Cancel';

      case 'delete':
        if (code == 'ar') return 'حذف';
        if (code == 'es') return 'Eliminar';
        if (code == 'fr') return 'Supprimer';
        if (code == 'de') return 'Löschen';
        if (code == 'tr') return 'Sil';
        if (code == 'hi') return 'हटाएं';
        if (code == 'zh') return '删除';
        return 'Delete';

      case 'no_documents_yet':
        if (code == 'ar') return 'لا توجد مستندات بعد';
        if (code == 'es') return 'Aún no hay documentos';
        if (code == 'fr') return 'Aucun document pour le moment';
        if (code == 'de') return 'Noch keine Dokumente';
        if (code == 'tr') return 'Henüz belge yok';
        if (code == 'hi') return 'अभी कोई दस्तावेज़ नहीं';
        if (code == 'zh') return '尚未添加文档';
        return 'No documents added yet';

      case 'add_document_title':
        if (code == 'ar') return 'إضافة مستند';
        if (code == 'es') return 'Añadir Documento';
        if (code == 'fr') return 'Ajouter un Document';
        if (code == 'de') return 'Dokument hinzufügen';
        if (code == 'tr') return 'Belge Ekle';
        if (code == 'hi') return 'दस्तावेज़ जोड़ें';
        if (code == 'zh') return '添加文档';
        return 'Add Document';

      case 'document_name_ast':
        if (code == 'ar') return 'اسم المستند *';
        if (code == 'es') return 'Nombre del Documento *';
        if (code == 'fr') return 'Nom du Document *';
        if (code == 'de') return 'Dokumentenname *';
        if (code == 'tr') return 'Belge Adı *';
        if (code == 'hi') return 'दस्तावेज़ का नाम *';
        if (code == 'zh') return '文档名称 *';
        return 'Document Name *';

      case 'choose_file_btn':
        if (code == 'ar') return 'اختر ملفاً';
        if (code == 'es') return 'Seleccionar Archivo';
        if (code == 'fr') return 'Choisir un Fichier';
        if (code == 'de') return 'Datei auswählen';
        if (code == 'tr') return 'Dosya Seç';
        if (code == 'hi') return 'फ़ाइल चुनें';
        if (code == 'zh') return '选择文件';
        return 'Choose File';

      case 'save_document_btn':
        if (code == 'ar') return 'حفظ المستند';
        if (code == 'es') return 'Guardar Documento';
        if (code == 'fr') return 'Enregistrer le Document';
        if (code == 'de') return 'Dokument speichern';
        if (code == 'tr') return 'Belgeyi Kaydet';
        if (code == 'hi') return 'दस्तावेज़ सहेजें';
        if (code == 'zh') return '保存文档';
        return 'Save Document';

      default:
        return key;
    }
  }

  IconData _iconFor(String fileType) {
    switch (fileType.trim().toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'video':
        return Icons.videocam;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'image':
        return Icons.image;

      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageDocument(DocumentModel document) {
    final type = document.fileType.trim().toLowerCase();

    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'image',
    ].contains(type);
  }

  Widget _buildImagePreview(DocumentModel document) {
    final bytes = document.bytes;
    final fileUrl = document.fileUrl?.trim() ?? '';

    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 70,
              color: Colors.red,
            ),
          );
        },
      );
    }

    if (fileUrl.isNotEmpty) {
      if (fileUrl.startsWith('data:image')) {
        try {
          final UriData? data = Uri.parse(fileUrl).data;

          if (data != null) {
            final dataBytes = data.contentAsBytes();

            if (dataBytes.isNotEmpty) {
              return Image.memory(
                dataBytes,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 70,
                      color: Colors.red,
                    ),
                  );
                },
              );
            }
          }
        } catch (_) {}
      }

      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        return Image.network(
          fileUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                size: 70,
                color: Colors.red,
              ),
            );
          },
        );
      }

      try {
        final localFile = File(fileUrl);

        if (localFile.existsSync()) {
          return Image.file(
            localFile,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 70,
                  color: Colors.red,
                ),
              );
            },
          );
        }
      } catch (_) {}

      try {
        String cleanBase64 = fileUrl;

        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        final decoded = base64Decode(cleanBase64);

        if (decoded.isNotEmpty) {
          return Image.memory(
            decoded,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 70,
                  color: Colors.red,
                ),
              );
            },
          );
        }
      } catch (_) {}
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 55,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No Image Preview Available',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenZoomable(DocumentModel document) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.5,
                    maxScale: 6.0,
                    boundaryMargin: const EdgeInsets.all(100),
                    child: _buildImagePreview(document),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pinch to zoom • Drag to move',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _buildShareDocumentMap(DocumentModel document) {
    final map = <String, dynamic>{
      'id': document.id,
      'name': document.name,
      'file_type': document.fileType,
      'fileType': document.fileType,
      'file_url': document.fileUrl ?? '',
      'fileUrl': document.fileUrl ?? '',
      'storage_path': document.fileUrl ?? '',
      'storagePath': document.fileUrl ?? '',
      'date': document.date.toIso8601String(),
    };

    final bytes = document.bytes;

    if (bytes != null && bytes.isNotEmpty) {
      final encoded = base64Encode(bytes);

      map['bytes'] = encoded;
      map['bytes_data'] = encoded;
    }

    return map;
  }

  Future<void> _shareDocument(DocumentModel document) async {
    try {
      final shareMap = _buildShareDocumentMap(document);

      final hasBytes = document.bytes != null && document.bytes!.isNotEmpty;

      debugPrint(
        'Sharing document: ${document.name} '
        '| type=${document.fileType} '
        '| bytes=${document.bytes?.length ?? 0} '
        '| hasBytes=$hasBytes',
      );

      await SharingService.shareMedications(
        name: document.name,
        medications: [],
        doctors: [],
        pharmacies: [],
        history: [],
        documents: [shareMap],
        insuranceCards: [],
      );
    } catch (e) {
      debugPrint('Error sharing document: $e');

      if (!mounted) return;

      _showMessage(
        'Error sharing document: $e',
        isError: true,
      );
    }
  }

  void _showEnlargedDocument(
    DocumentModel document,
    String code,
  ) {
    final isImage = _isImageDocument(document);

    String typeLbl = 'Type:';
    String dateLbl = 'Date:';
    String shareBtn = 'Share';
    String closeBtn = 'Close';
    String inspectTitle = 'Document Inspection';
    String tapToEnlarge = 'Tap image to enlarge and zoom';

    if (code == 'ar') {
      typeLbl = 'النوع:';
      dateLbl = 'التاريخ:';
      shareBtn = 'مشاركة';
      closeBtn = 'إغلاق';
      inspectTitle = 'معاينة المستند';
      tapToEnlarge = 'اضغط على الصورة للتكبير والتصغير';
    } else if (code == 'fr') {
      typeLbl = 'Type :';
      dateLbl = 'Date :';
      shareBtn = 'Partager';
      closeBtn = 'Fermer';
      inspectTitle = 'Inspection du Document';
      tapToEnlarge = 'Touchez l’image pour agrandir et zoomer';
    } else if (code == 'es') {
      typeLbl = 'Tipo:';
      dateLbl = 'Fecha:';
      shareBtn = 'Compartir';
      closeBtn = 'Cerrar';
      inspectTitle = 'Inspección de Documento';
      tapToEnlarge = 'Toque la imagen para ampliar y hacer zoom';
    } else if (code == 'de') {
      typeLbl = 'Typ:';
      dateLbl = 'Datum:';
      shareBtn = 'Teilen';
      closeBtn = 'Schließen';
      inspectTitle = 'Dokumentenüberprüfung';
      tapToEnlarge = 'Bild antippen zum Vergrößern und Zoomen';
    } else if (code == 'tr') {
      typeLbl = 'Tür:';
      dateLbl = 'Tarih:';
      shareBtn = 'Paylaş';
      closeBtn = 'Kapat';
      inspectTitle = 'Belge İnceleme';
      tapToEnlarge = 'Büyütmek ve yakınlaştırmak için resme dokunun';
    } else if (code == 'hi') {
      typeLbl = 'प्रकार:';
      dateLbl = 'तिथि:';
      shareBtn = 'साझा करें';
      closeBtn = 'बंद करें';
      inspectTitle = 'दस्तावेज़ निरीक्षण';
      tapToEnlarge = 'बड़ा करने और ज़ूम करने के लिए चित्र पर टैप करें';
    } else if (code == 'zh') {
      typeLbl = '类型:';
      dateLbl = '日期:';
      shareBtn = '分享';
      closeBtn = '关闭';
      inspectTitle = '文档检查';
      tapToEnlarge = '点击图片以放大和缩放';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _iconFor(document.fileType),
              color: Colors.teal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                document.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$typeLbl ${document.fileType.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$dateLbl '
                  '${document.date.day}/'
                  '${document.date.month}/'
                  '${document.date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                if (isImage)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(ctx).pop();

                      Future.microtask(() {
                        if (mounted) {
                          _openFullScreenZoomable(document);
                        }
                      });
                    },
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImagePreview(document),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.teal.shade200,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(document.fileType),
                          size: 50,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$inspectTitle '
                          '(${document.fileType.toUpperCase()})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isImage) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in,
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tapToEnlarge,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: Text(shareBtn),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _shareDocument(document);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(closeBtn),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  Future<void> _confirmDelete(String id) async {
    final language = context.read<LanguageProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_tr(language, 'delete')),
          content: Text(
            _tr(
              language,
              'delete_document_confirm',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                _tr(language, 'cancel'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _tr(language, 'delete'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<DocumentProvider>().deleteDocument(id);

      if (!mounted) return;

      _showMessage(
        'Document deleted successfully.',
      );
    } catch (e) {
      _showMessage(
        'Error deleting document: $e',
        isError: true,
      );
    }
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddDocumentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final language = context.watch<LanguageProvider>();
    final code = language.locale.languageCode;

    String datePrefix = 'Date:';

    if (code == 'ar') {
      datePrefix = 'التاريخ:';
    } else if (code == 'es') {
      datePrefix = 'Fecha:';
    } else if (code == 'fr') {
      datePrefix = 'Date :';
    } else if (code == 'de') {
      datePrefix = 'Datum:';
    } else if (code == 'tr') {
      datePrefix = 'Tarih:';
    } else if (code == 'hi') {
      datePrefix = 'तिथि:';
    } else if (code == 'zh') {
      datePrefix = '日期:';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr(language, 'documents_title'),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: _getIsLoading(provider)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : provider.documents.isEmpty
              ? _buildEmptyState(language)
              : RefreshIndicator(
                  onRefresh: () => _safeLoadDocs(provider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.documents.length,
                    itemBuilder: (context, index) {
                      final document = provider.documents[index];

                      return _DocumentCard(
                        document: document,
                        fallbackIcon: _iconFor(document.fileType),
                        datePrefix: datePrefix,
                        onTap: () => _showEnlargedDocument(
                          document,
                          code,
                        ),
                        onDelete: document.id.isEmpty
                            ? null
                            : () => _confirmDelete(
                                  document.id,
                                ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(
    LanguageProvider language,
  ) {
    return RefreshIndicator(
      onRefresh: () => _safeLoadDocs(
        context.read<DocumentProvider>(),
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tr(
                        language,
                        'no_documents_yet',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a scan, PDF, or video',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.fallbackIcon,
    required this.datePrefix,
    required this.onTap,
    this.onDelete,
  });

  final DocumentModel document;
  final IconData fallbackIcon;
  final String datePrefix;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  Widget _buildCardThumbnail() {
    final bytes = document.bytes;
    final fileUrl = document.fileUrl?.trim() ?? '';

    final isImage = [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'image',
    ].contains(
      document.fileType.trim().toLowerCase(),
    );

    if (isImage) {
      if (bytes != null && bytes.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Icon(
                fallbackIcon,
                color: Colors.teal,
              );
            },
          ),
        );
      }

      if (fileUrl.isNotEmpty) {
        if (fileUrl.startsWith('data:image')) {
          try {
            final UriData? data = Uri.parse(fileUrl).data;

            if (data != null) {
              final dataBytes = data.contentAsBytes();

              if (dataBytes.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    dataBytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        fallbackIcon,
                        color: Colors.teal,
                      );
                    },
                  ),
                );
              }
            }
          } catch (_) {}
        }

        if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fileUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  fallbackIcon,
                  color: Colors.teal,
                );
              },
            ),
          );
        }

        try {
          final file = File(fileUrl);

          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    fallbackIcon,
                    color: Colors.teal,
                  );
                },
              ),
            );
          }
        } catch (_) {}

        try {
          String cleanBase64 = fileUrl;

          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }

          final decoded = base64Decode(cleanBase64);

          if (decoded.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                decoded,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    fallbackIcon,
                    color: Colors.teal,
                  );
                },
              ),
            );
          }
        } catch (_) {}
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        fallbackIcon,
        color: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildCardThumbnail(),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$datePrefix ${document.date.day}/'
          '${document.date.month}/'
          '${document.date.year}',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Enlarge / Inspect',
              icon: const Icon(
                Icons.visibility,
                color: Colors.teal,
              ),
              onPressed: onTap,
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet();

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'pdf',
    'mp4',
    'mov',
    'avi',
  ];

  final TextEditingController _nameController = TextEditingController();

  DateTime _date = DateTime.now();

  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileType;

  bool _isSaving = false;

  bool get _selectedFileIsImage {
    final type = _fileType?.trim().toLowerCase() ?? '';

    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'image',
    ].contains(type);
  }

  String _tr(
    LanguageProvider language,
    String key,
  ) {
    final code = language.locale.languageCode;

    switch (key) {
      case 'add_document_title':
        if (code == 'ar') return 'إضافة مستند';
        if (code == 'es') return 'Añadir Documento';
        if (code == 'fr') return 'Ajouter un Document';
        if (code == 'de') return 'Dokument hinzufügen';
        if (code == 'tr') return 'Belge Ekle';
        if (code == 'hi') return 'दस्तावेज़ जोड़ें';
        if (code == 'zh') return '添加文档';
        return 'Add Document';

      case 'document_name_ast':
        if (code == 'ar') return 'اسم المستند *';
        if (code == 'es') return 'Nombre del Documento *';
        if (code == 'fr') return 'Nom du Document *';
        if (code == 'de') return 'Dokumentenname *';
        if (code == 'tr') return 'Belge Adı *';
        if (code == 'hi') return 'दस्तावेज़ का नाम *';
        if (code == 'zh') return '文档名称 *';
        return 'Document Name *';

      case 'choose_file_btn':
        if (code == 'ar') return 'اختر ملفاً';
        if (code == 'es') return 'Seleccionar Archivo';
        if (code == 'fr') return 'Choisir un Fichier';
        if (code == 'de') return 'Datei auswählen';
        if (code == 'tr') return 'Dosya Seç';
        if (code == 'hi') return 'फ़ाइल चुनें';
        if (code == 'zh') return '选择文件';
        return 'Choose File';

      case 'save_document_btn':
        if (code == 'ar') return 'حفظ المستند';
        if (code == 'es') return 'Guardar Documento';
        if (code == 'fr') return 'Enregistrer le Document';
        if (code == 'de') return 'Dokument speichern';
        if (code == 'tr') return 'Belgeyi Kaydet';
        if (code == 'hi') return 'दस्तावेज़ सहेजें';
        if (code == 'zh') return '保存文档';
        return 'Save Document';

      default:
        return key;
    }
  }

  Future<void> _pickFile() async {
    if (_isSaving) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage(
          'Could not read the selected file.',
          isError: true,
        );
        return;
      }

      final extension = _getFileExtension(pickedFile);

      if (!_allowedExtensions.contains(extension)) {
        _showMessage(
          'This file type is not supported.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _fileBytes = bytes;
        _fileName = pickedFile.name;
        _fileType = extension;
      });
    } catch (e) {
      _showMessage(
        'Error selecting file: $e',
        isError: true,
      );
    }
  }

  String _getFileExtension(PlatformFile file) {
    final extension = file.extension?.trim().toLowerCase() ?? '';

    if (extension.isNotEmpty) {
      return extension;
    }

    final fileName = file.name.trim();

    if (!fileName.contains('.')) {
      return '';
    }

    return fileName.split('.').last.trim().toLowerCase();
  }

  Future<void> _pickDate() async {
    if (_isSaving) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _date = picked;
    });
  }

  void _openSelectedImageZoom() {
    final bytes = _fileBytes;

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    minScale: 0.5,
                    maxScale: 6.0,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedFilePreview() {
    final bytes = _fileBytes;

    if (bytes == null || bytes.isEmpty || !_selectedFileIsImage) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openSelectedImageZoom,
          child: Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.teal.shade300,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.touch_app,
                size: 18,
                color: Colors.teal,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap the photo to enlarge and zoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generateUuidV4() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int value) {
      return value.toRadixString(16).padLeft(2, '0');
    }

    final hex = bytes.map(hexByte).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final bytes = _fileBytes;
    final fileType = _fileType ?? 'doc';

    if (name.isEmpty) {
      _showMessage(
        'Please enter a document name.',
      );
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      _showMessage(
        'Please choose a document file.',
      );
      return;
    }

    if (fileType.isEmpty) {
      _showMessage(
        'Could not determine the file type.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newDoc = DocumentModel(
        id: _generateUuidV4(),
        name: name,
        fileType: fileType,
        date: _date,
        bytes: bytes,
      );

      await context.read<DocumentProvider>().addDocument(newDoc);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document saved successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showMessage(
        'Error saving document: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(
                  language,
                  'add_document_title',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _tr(
                    language,
                    'document_name_ast',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_isSaving,
                title: Text(
                  'Date: ${_date.day}/'
                  '${_date.month}/'
                  '${_date.year}',
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: _isSaving ? null : _pickDate,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickFile,
                  icon: const Icon(
                    Icons.attach_file,
                  ),
                  label: Text(
                    _fileName ??
                        _tr(
                          language,
                          'choose_file_btn',
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              _buildSelectedFilePreview(),
              if (_fileType != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Type: ${_fileType!.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _tr(
                            language,
                            'save_document_btn',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
