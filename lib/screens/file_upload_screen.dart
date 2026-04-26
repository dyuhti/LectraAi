import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:smart_lecture_notes/services/web_file_picker.dart';
import 'package:smart_lecture_notes/screens/document_processing_screen.dart';
import 'package:smart_lecture_notes/routes/page_transitions.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({Key? key}) : super(key: key);

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  static const int _maxUploadSizeBytes = 10 * 1024 * 1024;

  List<UploadedFile> uploadedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Upload PDF or Image',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag and Drop Zone
            _buildDragDropZone(),
            const SizedBox(height: 24),

            // OR Divider
            const Row(
              children: [
                Expanded(
                  child: Divider(color: AppColors.border),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: AppColors.border),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Upload Options
            const Text(
              'Quick Options',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickOption(
                    icon: Icons.folder_open,
                    label: 'From Files',
                    color: AppColors.primaryLight,
                    onPressed: () {
                      _pickFromFiles();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickOption(
                    icon: Icons.image,
                    label: 'From Gallery',
                    color: AppColors.primaryLight,
                    onPressed: () {
                      _pickFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upload Progress (if uploading)
            if (_isUploading) _buildUploadProgress(),
            const SizedBox(height: 24),

            // Supported Formats Info
            _buildSupportedFormats(),
            const SizedBox(height: 24),

            // Uploaded Files List
            if (uploadedFiles.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recently Uploaded',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...uploadedFiles.map((file) => _buildFileItem(file)),
                  const SizedBox(height: 20),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDragDropZone() {
    return GestureDetector(
      onTap: () {
        _pickFromFiles();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: AppDecorations.card(),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: AppDecorations.iconContainer(radius: 14),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primaryLight,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Drag & Drop files here',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'or click to browse from your device',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PDF, JPG, PNG, DOC (Max 10MB)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppDecorations.card(),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppDecorations.iconContainer(radius: 12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uploading...',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFormats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.iconContainer(radius: 10),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primaryLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supported Formats',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PDF, JPG, PNG, DOC, DOCX, PPTX',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Max file size: 10 MB',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(UploadedFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecorations.iconContainer(radius: 12),
            child: Icon(
              file.icon,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      file.size,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.status,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Get.snackbar(
                'Options',
                'File options menu',
                backgroundColor: AppColors.primary,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromFiles() async {
    try {
      if (kIsWeb) {
        final webFiles = await pickFilesForWeb(
          allowedExtensions: const [
            'pdf',
            'jpg',
            'jpeg',
            'png',
            'doc',
            'docx',
            'pptx',
          ],
          allowMultiple: true,
        );
        if (webFiles.isEmpty) return;

        final picked = webFiles
            .map(
              (f) => _PickedUpload(
                name: f.name,
                path: null,
                  bytes: f.bytes,
                sizeBytes: f.sizeBytes,
              ),
            )
            .toList();

        final oversized =
            picked.where((file) => file.sizeBytes > _maxUploadSizeBytes).toList();
        if (oversized.isNotEmpty) {
          Get.snackbar(
            'File too large',
            'File too large. Max size is 10MB.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
          return;
        }

        await _simulateFileUpload(selectedFiles: picked);
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        withData: kIsWeb,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'pptx',
        ],
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files
          .map(
            (f) => _PickedUpload(
              name: f.name,
              path: f.path,
              bytes: f.bytes,
              sizeBytes: f.size,
            ),
          )
          .toList();

      final oversized = picked.where((file) => file.sizeBytes > _maxUploadSizeBytes).toList();
      if (oversized.isNotEmpty) {
        Get.snackbar(
          'File too large',
          'File too large. Max size is 10MB.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return;
      }

      await _simulateFileUpload(selectedFiles: picked);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open file picker',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      final picked = <_PickedUpload>[];
      for (final image in images) {
        final bytes = await image.length();
        if (bytes > _maxUploadSizeBytes) {
          Get.snackbar(
            'File too large',
            'File too large. Max size is 10MB.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
          return;
        }
        picked.add(
          _PickedUpload(
            name: p.basename(image.path),
            path: image.path,
            bytes: null,
            sizeBytes: bytes,
          ),
        );
      }

      await _simulateFileUpload(selectedFiles: picked);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open gallery',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    }
  }

  IconData _iconForFilename(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.doc':
      case '.docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  Future<void> _simulateFileUpload({required List<_PickedUpload> selectedFiles}) async {
    if (selectedFiles.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _uploadProgress = 0.35);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _uploadProgress = 0.75);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _uploadProgress = 1.0;
      _isUploading = false;

      for (final file in selectedFiles) {
        uploadedFiles.insert(
          0,
          UploadedFile(
            name: file.name,
            size: _formatBytes(file.sizeBytes),
            status: 'Processing',
            color: AppColors.primaryLight,
            icon: _iconForFilename(file.name),
          ),
        );
      }
    });

    Get.snackbar(
      'Success',
      selectedFiles.length == 1
          ? 'File selected successfully! Processing...'
          : '${selectedFiles.length} files selected successfully! Processing...',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    final primary = selectedFiles.first;
    Navigator.of(context).push(
      AppPageTransitions.fadeSlide(
        DocumentProcessingScreen(
          fileName: primary.name,
          filePath: primary.path,
          fileBytes: primary.bytes,
          isExtract: true,
          isSummarize: true,
          isKeyword: true,
        ),
      ),
    );
  }
}

class _PickedUpload {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final int sizeBytes;

  const _PickedUpload({
    required this.name,
    required this.path,
    required this.bytes,
    required this.sizeBytes,
  });
}

class UploadedFile {
  final String name;
  final String size;
  final String status;
  final Color color;
  final IconData icon;

  UploadedFile({
    required this.name,
    required this.size,
    required this.status,
    required this.color,
    required this.icon,
  });
}
