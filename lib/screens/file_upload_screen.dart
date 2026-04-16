import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/screens/document_processing_screen.dart';
import 'package:smart_lecture_notes/routes/page_transitions.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({Key? key}) : super(key: key);

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  List<UploadedFile> uploadedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0;

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
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColors.border),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      Get.snackbar(
                        'File Manager',
                        'Opening file manager...',
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                      );
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
                      Get.snackbar(
                        'Gallery',
                        'Opening gallery...',
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                      );
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

            // Processing Options
            const Text(
              'Processing Options',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildProcessingOption(
              icon: Icons.auto_awesome,
              title: 'AI Text Extraction',
              description: 'Extract and digitize text using OCR',
            ),
            const SizedBox(height: 10),
            _buildProcessingOption(
              icon: Icons.summarize,
              title: 'Auto Summarize',
              description: 'Generate summary of extracted content',
            ),
            const SizedBox(height: 10),
            _buildProcessingOption(
              icon: Icons.label,
              title: 'Keyword Extraction',
              description: 'Identify key topics and concepts',
            ),
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
        Get.snackbar(
          'Upload',
          'File picker opened...',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
        _simulateFileUpload();
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
            Text(
              'or click to browse from your device',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PDF, JPG, PNG, DOC up to 50MB',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
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
          Expanded(
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
                Text(
                  'PDF, JPG, PNG, DOC, DOCX, PPTX',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOption({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecorations.iconContainer(radius: 12),
            child: Icon(
              icon,
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
                  title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: true,
            onChanged: (value) {},
            fillColor: WidgetStateProperty.all(AppColors.primary),
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
                      style: TextStyle(
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
                        style: TextStyle(
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

  void _simulateFileUpload() {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _uploadProgress = 0.3);
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _uploadProgress = 0.7);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _isUploading = false;
        });

        uploadedFiles.add(
          UploadedFile(
            name: 'Lecture_Physics_Ch5.pdf',
            size: '2.4 MB',
            status: 'Processing',
            color: const Color(0xFF5B7FFF),
            icon: Icons.picture_as_pdf,
          ),
        );

        Get.snackbar(
          'Success',
          'File uploaded successfully! Processing...',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.of(context).push(
            AppPageTransitions.fadeSlide(const DocumentProcessingScreen()),
          );
        });
      }
    });
  }
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
