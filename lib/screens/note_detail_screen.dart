import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  final String? noteTitle;
  final String? categoryName;

  const NoteDetailScreen({
    Key? key,
    this.note,
    this.noteTitle = 'Lecture on Data Structures',
    this.categoryName = 'Data Structures',
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _expandFormulasController;
  late AnimationController _expandKeyPointsController;
  late AnimationController _expandExamplesController;

  bool _isEditMode = false;
  bool _expandFormulas = true;
  bool _expandKeyPoints = true;
  bool _expandExamples = true;

  // Text editing controllers
  late TextEditingController _titleController;
  late TextEditingController _overviewController;
  late TextEditingController _formulasController;
  late TextEditingController _keyPointsController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _expandFormulasController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandKeyPointsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandExamplesController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final note = widget.note;

    // Initialize controllers (prefer passed-in Note data)
    _titleController = TextEditingController(
      text: note?.title ?? widget.noteTitle ?? 'Lecture on Data Structures',
    );
    _overviewController = TextEditingController(
      text: note?.content ??
          'Today we\'re discussing linked lists and their implementation. A linked list is a linear data structure where elements are stored in nodes. Each node contains data and a reference to the next node.',
    );
    _formulasController = TextEditingController(
      text: note?.summary ??
          'Loss Function: L = 1/n Σ(y_pred - y_actual)²\nSigmoid Activation: σ(x) = 1 / (1 + e^(-x))\nGradient Descent: θ = θ - αν(θ)',
    );
    _keyPointsController = TextEditingController(
      text: 'Neural networks consist of input, hidden and output layers\nActivation functions introduce non-linearity\nTraining requires labeled data and optimization\nOverfitting can be prevented with regularization',
    );

    // Start animations
    _expandFormulasController.forward();
    _expandKeyPointsController.forward();
    _expandExamplesController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expandFormulasController.dispose();
    _expandKeyPointsController.dispose();
    _expandExamplesController.dispose();
    _titleController.dispose();
    _overviewController.dispose();
    _formulasController.dispose();
    _keyPointsController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Save data when exiting edit mode
        Get.snackbar(
          'Note Updated',
          'Your changes have been saved',
          backgroundColor: AppColors.primary.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    });
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
            icon: Icon(
              _isEditMode ? Icons.check_circle : Icons.edit,
              color: _isEditMode ? AppColors.primaryLight : AppColors.primary,
              size: 24,
            ),
            onPressed: _toggleEditMode,
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
                            widget.note?.subject ??
                                widget.categoryName ??
                                'Data Structures',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                        Text(
                          widget.note != null
                              ? MaterialLocalizations.of(context)
                                  .formatFullDate(widget.note!.createdAt)
                              : 'April 14, 2026',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note Title
                  _isEditMode
                      ? TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2A8A),
                            height: 1.3,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFDCE6FF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 2,
                        )
                      : Text(
                          _titleController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2A8A),
                            height: 1.3,
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Main Content - Overview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDCE6FF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2A8A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isEditMode
                            ? TextField(
                                controller: _overviewController,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF334155),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Write overview...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFDCE6FF),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                maxLines: 4,
                              )
                            : Text(
                                _overviewController.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF334155),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Formulas Section
                  _buildExpandableSection(
                    title: 'Formulas',
                    count: 3,
                    icon: Icons.functions,
                    isExpanded: _expandFormulas,
                    animationController: _expandFormulasController,
                    onTap: () {
                      setState(() => _expandFormulas = !_expandFormulas);
                      if (_expandFormulas) {
                        _expandFormulasController.forward();
                      } else {
                        _expandFormulasController.reverse();
                      }
                    },
                    isEditMode: _isEditMode,
                    editController: _formulasController,
                  ),
                  const SizedBox(height: 16),

                  // Key Points Section
                  _buildExpandableSection(
                    title: 'Key Points',
                    count: 4,
                    icon: Icons.lightbulb,
                    isExpanded: _expandKeyPoints,
                    animationController: _expandKeyPointsController,
                    onTap: () {
                      setState(() => _expandKeyPoints = !_expandKeyPoints);
                      if (_expandKeyPoints) {
                        _expandKeyPointsController.forward();
                      } else {
                        _expandKeyPointsController.reverse();
                      }
                    },
                    isEditMode: _isEditMode,
                    editController: _keyPointsController,
                  ),
                  const SizedBox(height: 16),

                  // Examples Section
                  _buildExpandableSection(
                    title: 'Examples',
                    count: 2,
                    icon: Icons.science,
                    isExpanded: _expandExamples,
                    animationController: _expandExamplesController,
                    onTap: () {
                      setState(() => _expandExamples = !_expandExamples);
                      if (_expandExamples) {
                        _expandExamplesController.forward();
                      } else {
                        _expandExamplesController.reverse();
                      }
                    },
                    isEditMode: false,
                  ),
                  const SizedBox(height: 120), // Space for fixed bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
              spreadRadius: 1,
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
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required IconData icon,
    required bool isExpanded,
    required AnimationController animationController,
    required VoidCallback onTap,
    required bool isEditMode,
    TextEditingController? editController,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE6FF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getIconColor(title).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: _getIconColor(title),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$title ($count)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2A8A),
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(animationController),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(animationController),
              child: FadeTransition(
                opacity: animationController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.02),
                    border: const Border(
                      top: BorderSide(
                        color: Color(0xFFDCE6FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildSectionContent(
                      title,
                      isEditMode,
                      editController,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionContent(
    String title,
    bool isEditMode,
    TextEditingController? editController,
  ) {
    if (isEditMode && editController != null) {
      return [
        TextField(
          controller: editController,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF334155),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Edit $title...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFDCE6FF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 6,
        ),
      ];
    }

    if (title == 'Formulas') {
      return _buildFormulaItems();
    } else if (title == 'Key Points') {
      return _buildKeyPointItems();
    } else if (title == 'Examples') {
      return _buildExampleItems();
    }
    return [];
  }

  List<Widget> _buildFormulaItems() {
    return [
      _buildFormulaItem('Loss Function: L = 1/n Σ(y_pred - y_actual)²'),
      const SizedBox(height: 12),
      _buildFormulaItem('Sigmoid Activation: σ(x) = 1 / (1 + e^(-x))'),
      const SizedBox(height: 12),
      _buildFormulaItem('Gradient Descent: θ = θ - αν(θ)'),
    ];
  }

  List<Widget> _buildKeyPointItems() {
    return [
      _buildBulletPoint(
        'Neural networks consist of input, hidden and output layers',
      ),
      const SizedBox(height: 12),
      _buildBulletPoint(
        'Activation functions introduce non-linearity',
      ),
      const SizedBox(height: 12),
      _buildBulletPoint(
        'Training requires labeled data and optimization',
      ),
      const SizedBox(height: 12),
      _buildBulletPoint(
        'Overfitting can be prevented with regularization',
      ),
    ];
  }

  List<Widget> _buildExampleItems() {
    return [
      _buildBulletPoint(
        'Image recognition and classification',
      ),
      const SizedBox(height: 12),
      _buildBulletPoint(
        'Natural language processing and translation',
      ),
    ];
  }

  Widget _buildFormulaItem(String formula) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDCE6FF),
          width: 1,
        ),
      ),
      child: Text(
        formula,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0A2A8A),
          fontFamily: 'Courier',
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3, right: 12),
          child: Text(
            '•',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.6,
              fontWeight: FontWeight.w500,
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
