import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final String? noteTitle;
  final String? categoryName;

  const NoteDetailScreen({
    Key? key,
    this.noteTitle = 'Lecture on Data Structures',
    this.categoryName = 'Data Structures',
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late ScrollController _scrollController;
  bool _expandFormulas = true;
  bool _expandKeyPoints = true;
  bool _expandExamples = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _editNote() {
    Get.snackbar(
      'Edit Note',
      'Opening note editor...',
      backgroundColor: AppColors.primary.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  void _deleteNote() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
              Get.snackbar(
                'Note Deleted',
                'Your note has been removed',
                backgroundColor: AppColors.primary.withOpacity(0.9),
                colorText: Colors.white,
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  void _exportPDF() {
    Get.snackbar(
      'Exporting...',
      'Generating PDF file...',
      backgroundColor: AppColors.primary.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: _editNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.primaryDark),
            onPressed: _deleteNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.categoryName ?? 'Data Structures',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'April 14, 2026',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note Title
                  Text(
                    widget.noteTitle ?? 'Lecture on Data Structures',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Today we\'re discussing linked lists and their implementation. A linked list is a linear data structure where elements are stored in nodes. Each node contains data and a reference to the next node.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Formulas Section
                  _buildExpandableSection(
                    title: 'Formulas',
                    count: 3,
                    icon: Icons.functions,
                    isExpanded: _expandFormulas,
                    onTap: () {
                      setState(() => _expandFormulas = !_expandFormulas);
                    },
                    children: _expandFormulas
                        ? [
                            _buildFormulaItem(
                              'Loss Function: L = 1/n Σ(y_pred - y_actual)²',
                            ),
                            const SizedBox(height: 12),
                            _buildFormulaItem(
                              'Sigmoid Activation: σ(x) = 1 / (1 + e^(-x))',
                            ),
                            const SizedBox(height: 12),
                            _buildFormulaItem(
                              'Gradient Descent: θ = θ - αν(θ)',
                            ),
                          ]
                        : [],
                  ),
                  const SizedBox(height: 12),

                  // Key Points Section
                  _buildExpandableSection(
                    title: 'Key Points',
                    count: 4,
                    icon: Icons.lightbulb,
                    isExpanded: _expandKeyPoints,
                    onTap: () {
                      setState(() => _expandKeyPoints = !_expandKeyPoints);
                    },
                    children: _expandKeyPoints
                        ? [
                            _buildBulletPoint(
                              'Neural networks consist of input, hidden and output layers',
                            ),
                            const SizedBox(height: 8),
                            _buildBulletPoint(
                              'Activation functions introduce non-linearity',
                            ),
                            const SizedBox(height: 8),
                            _buildBulletPoint(
                              'Training requires labeled data and optimization',
                            ),
                            const SizedBox(height: 8),
                            _buildBulletPoint(
                              'Overfitting can be prevented with regularization',
                            ),
                          ]
                        : [],
                  ),
                  const SizedBox(height: 12),

                  // Examples Section
                  _buildExpandableSection(
                    title: 'Examples',
                    count: 2,
                    icon: Icons.science,
                    isExpanded: _expandExamples,
                    onTap: () {
                      setState(() => _expandExamples = !_expandExamples);
                    },
                    children: _expandExamples
                        ? [
                            _buildBulletPoint(
                              'Image recognition and classification',
                            ),
                            const SizedBox(height: 8),
                            _buildBulletPoint(
                              'Natural language processing and translation',
                            ),
                          ]
                        : [],
                  ),
                  const SizedBox(height: 120), // Space for floating button
                ],
              ),
            ),
          ),

          // Sticky Export Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _exportPDF,
                  style: AppButtonStyles.primary(radius: 14),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Export as PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getIconColor(title).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: _getIconColor(title),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title ($count)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.04),
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormulaItem(String formula) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(
        color: AppColors.primaryLight.withOpacity(0.08),
      ),
      child: Text(
        formula,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontFamily: 'Courier',
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, right: 8),
          child: Text(
            '•',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Color _getIconColor(String title) {
    switch (title) {
      case 'Formulas':
        return AppColors.primaryLight;
      case 'Key Points':
        return AppColors.primary;
      case 'Examples':
        return AppColors.primaryDark;
      default:
        return AppColors.primaryLight;
    }
  }
}
