import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/screens/preview_document_screen.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class DocumentProcessingScreen extends StatefulWidget {
  const DocumentProcessingScreen({Key? key}) : super(key: key);

  @override
  State<DocumentProcessingScreen> createState() =>
      _DocumentProcessingScreenState();
}

class _DocumentProcessingScreenState extends State<DocumentProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Simulate processing and navigate to preview after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Get.off(() => const PreviewDocumentScreen());
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

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
          'Upload Document',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rotating loader
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryLight,
                    width: 4,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Processing document...',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Using AI to extract and analyze content',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // Processing steps
            Column(
              children: [
                _buildProcessingStep('Uploading file', 1),
                _buildProcessingStep('Analyzing content', 2),
                _buildProcessingStep('Generating summary', 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStep(String label, int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step <= 3 ? AppColors.primaryLight : AppColors.border,
            ),
            child: Center(
              child: step <= 3
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: step <= 3 ? AppColors.primary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
