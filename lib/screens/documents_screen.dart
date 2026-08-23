import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import '../providers/document_provider.dart';
import '../providers/language_provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() =>
      _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DocumentProvider>().loadDocuments();
    });
  }

  // ============================================================
  // PICK AND UPLOAD
  // ============================================================

  Future<void> _pickAndUpload() async {
    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
          'doc',
          'docx',
        ],
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final picked = result.files.single;

      final bytes = picked.bytes ??
          (picked.path != null
              ? await File(
                  picked.path!,
                ).readAsBytes()
              : null);

      if (bytes == null ||
          bytes.isEmpty) {
        throw StateError(
          'The selected file could not be read.',
        );
      }

      if (!mounted) {
        return;
      }

      final nameController =
          TextEditingController(
        text: picked.name,
      );

      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Add Document',
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Document name',
                border:
                    OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () {
                  final value =
                      nameController.text
                          .trim();

                  if (value.isNotEmpty) {
                    Navigator.pop(
                      dialogContext,
                      value,
                    );
                  }
                },
                child: const Text(
                  'Continue',
                ),
              ),
            ],
          );
        },
      );

      nameController.dispose();

      if (name == null ||
          name.trim().isEmpty) {
        return;
      }

      final extension =
          _extensionOf(picked.name);

      /*
       * IMPORTANT:
       *
       * userId and guestId are intentionally
       * left empty here.
       *
       * DocumentProvider is responsible for
       * assigning the correct owner:
       *
       * authenticated user -> userId
       * guest              -> guestId
       */
      final document = DocumentModel(
        id: _generateId(),
        userId: '',
        guestId: '',
        name: name.trim(),
        fileType: extension,
        date: DateTime.now(),
        bytes: bytes,
      );

      await context
          .read<DocumentProvider>()
          .addDocument(document);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Document uploaded successfully.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Document upload failed:\n'
        '$error\n'
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to upload the document.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _delete(
    DocumentModel document,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete document?',
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${document.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    try {
      await context
          .read<DocumentProvider>()
          .deleteDocument(
            document.id,
          );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Document deleted.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Document deletion failed:\n'
        '$error\n'
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete the document.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<void> _share(
    DocumentModel document,
  ) async {
    try {
      /*
       * Local document bytes are preferred.
       */
      if (document.bytes != null &&
          document.bytes!.isNotEmpty) {
        final tempDirectory =
            await Directory.systemTemp
                .createTemp(
          'sana_share_',
        );

        final extension =
            _extensionOf(
          document.name,
        );

        final file = File(
          '${tempDirectory.path}/'
          '${_safeFileName(document.name, extension)}',
        );

        await file.writeAsBytes(
          document.bytes!,
          flush: true,
        );

        await SharePlus.instance.share(
          ShareParams(
            text:
                'SANA medical document: '
                '${document.name}',
            files: [
              XFile(
                file.path,
              ),
            ],
          ),
        );

        return;
      }

      /*
       * Cloud documents remain private.
       *
       * DocumentProvider validates ownership
       * before generating a temporary signed URL.
       */
      if (!mounted) {
        return;
      }

      final provider =
          context.read<DocumentProvider>();

      final signedUrl =
          await provider
              .getSignedDocumentUrl(
        document,
      );

      if (!mounted) {
        return;
      }

      if (signedUrl == null ||
          signedUrl.isEmpty) {
        _showMessage(
          'This document cannot be shared right now.',
          isError: true,
        );

        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text:
              'SANA medical document: '
              '${document.name}\n\n'
              '$signedUrl',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Document sharing failed:\n'
        '$error\n'
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to share the document.',
        isError: true,
      );
    }
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  Future<void> _preview(
    DocumentModel document,
  ) async {
    final provider =
        context.read<DocumentProvider>();

    String? signedUrl;

    if ((document.bytes == null ||
            document.bytes!.isEmpty) &&
        document.storagePath != null &&
        document.storagePath!
            .trim()
            .isNotEmpty) {
      signedUrl =
          await provider
              .getSignedDocumentUrl(
        document,
      );
    }

    if (!mounted) {
      return;
    }

    final isImage =
        _isImage(document);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconFor(
                          document.fileType,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          document.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Flexible(
                    child:
                        _buildPreviewContent(
                      document,
                      signedUrl,
                      isImage,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Type: '
                    '${document.fileType.toUpperCase()}',
                  ),
                  Text(
                    'Date: '
                    '${_formatDate(document.date)}',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );

                      _share(
                        document,
                      );
                    },
                    icon: const Icon(
                      Icons.share,
                    ),
                    label: const Text(
                      'Share',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent(
    DocumentModel document,
    String? signedUrl,
    bool isImage,
  ) {
    if (isImage) {
      if (document.bytes != null &&
          document.bytes!.isNotEmpty) {
        return InteractiveViewer(
          child: Image.memory(
            document.bytes!,
            fit: BoxFit.contain,
          ),
        );
      }

      if (signedUrl != null &&
          signedUrl.isNotEmpty) {
        return InteractiveViewer(
          child: Image.network(
            signedUrl,
            fit: BoxFit.contain,
            errorBuilder:
                (
              context,
              error,
              stackTrace,
            ) {
              return const _PreviewUnavailable();
            },
          ),
        );
      }
    }

    return _PreviewUnavailable(
      message:
          document.fileType
                      .trim()
                      .toLowerCase() ==
                  'pdf'
              ? 'PDF preview is not available here.\n'
                  'Use Share to open it.'
              : 'Preview is not available for this file type.',
      icon:
          document.fileType
                      .trim()
                      .toLowerCase() ==
                  'pdf'
              ? Icons.picture_as_pdf
              : Icons.insert_drive_file,
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final provider =
        context.watch<DocumentProvider>();

    final language =
        context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleFor(
            language.locale.languageCode,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () {
                        provider
                            .loadDocuments();
                      },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _isUploading
                ? null
                : _pickAndUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.upload_file,
              ),
        label: Text(
          _isUploading
              ? 'Uploading...'
              : 'Add document',
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            provider.loadDocuments,
        child: _buildBody(
          provider,
        ),
      ),
    );
  }

  Widget _buildBody(
    DocumentProvider provider,
  ) {
    if (provider.isLoading &&
        provider.documents.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (provider.documents.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 120,
          ),
          Icon(
            Icons.folder_open,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(
            height: 16,
          ),
          Center(
            child: Text(
              'No documents added yet.',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Center(
              child: Text(
                'Upload prescriptions, reports, '
                'scans and other health files.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        100,
      ),
      itemCount:
          provider.documents.length,
      separatorBuilder:
          (context, index) {
        return const SizedBox(
          height: 8,
        );
      },
      itemBuilder:
          (context, index) {
        final document =
            provider.documents[
                index];

        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading:
                CircleAvatar(
              child: Icon(
                _iconFor(
                  document.fileType,
                ),
              ),
            ),
            title: Text(
              document.name,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${document.fileType.toUpperCase()} • '
              '${_formatDate(document.date)}',
            ),
            onTap: () {
              _preview(
                document,
              );
            },
            trailing:
                PopupMenuButton<String>(
              onSelected:
                  (value) {
                switch (value) {
                  case 'preview':
                    _preview(
                      document,
                    );
                    break;

                  case 'share':
                    _share(
                      document,
                    );
                    break;

                  case 'delete':
                    _delete(
                      document,
                    );
                    break;
                }
              },
              itemBuilder:
                  (context) {
                return const [
                  PopupMenuItem(
                    value:
                        'preview',
                    child: ListTile(
                      leading:
                          Icon(
                        Icons
                            .visibility,
                      ),
                      title:
                          Text(
                        'Preview',
                      ),
                      contentPadding:
                          EdgeInsets
                              .zero,
                    ),
                  ),
                  PopupMenuItem(
                    value:
                        'share',
                    child: ListTile(
                      leading:
                          Icon(
                        Icons.share,
                      ),
                      title:
                          Text(
                        'Share',
                      ),
                      contentPadding:
                          EdgeInsets
                              .zero,
                    ),
                  ),
                  PopupMenuItem(
                    value:
                        'delete',
                    child: ListTile(
                      leading:
                          Icon(
                        Icons
                            .delete_outline,
                      ),
                      title:
                          Text(
                        'Delete',
                      ),
                      contentPadding:
                          EdgeInsets
                              .zero,
                    ),
                  ),
                ];
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _titleFor(
    String code,
  ) {
    switch (code) {
      case 'ar':
        return 'المستندات';

      case 'fr':
        return 'Documents';

      case 'es':
        return 'Documentos';

      case 'de':
        return 'Dokumente';

      case 'tr':
        return 'Belgeler';

      case 'hi':
        return 'दस्तावेज़';

      case 'zh':
        return '文档';

      default:
        return 'Medical Documents';
    }
  }

  bool _isImage(
    DocumentModel document,
  ) {
    return const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'image',
    }.contains(
      document.fileType
          .trim()
          .toLowerCase(),
    );
  }

  IconData _iconFor(
    String fileType,
  ) {
    switch (
        fileType.trim().toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'image':
        return Icons.image;

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'video':
        return Icons.video_file;

      case 'doc':
      case 'docx':
        return Icons.description;

      default:
        return Icons.insert_drive_file;
    }
  }

  String _extensionOf(
    String fileName,
  ) {
    final dot =
        fileName.lastIndexOf('.');

    if (dot < 0 ||
        dot == fileName.length - 1) {
      return 'bin';
    }

    return fileName
        .substring(dot + 1)
        .toLowerCase();
  }

  String _safeFileName(
    String name,
    String extension,
  ) {
    var cleaned = name
        .replaceAll(
          RegExp(
            r'[\\/:*?"<>|]',
          ),
          '_',
        )
        .trim();

    if (cleaned.isEmpty) {
      cleaned =
          'document.$extension';
    }

    return cleaned;
  }

  String _generateId() {
    final now =
        DateTime.now();

    return '${now.microsecondsSinceEpoch}_'
        '${now.millisecondsSinceEpoch}';
  }

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : null,
      ),
    );
  }
}

// ============================================================
// PREVIEW UNAVAILABLE
// ============================================================

class _PreviewUnavailable
    extends StatelessWidget {
  const _PreviewUnavailable({
    this.message =
        'Preview is not available.',
    this.icon =
        Icons.visibility_off_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}