import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class HelpTutorialScreen extends StatefulWidget {
  const HelpTutorialScreen({Key? key}) : super(key: key);

  @override
  State<HelpTutorialScreen> createState() => _HelpTutorialScreenState();
}

class _HelpTutorialScreenState extends State<HelpTutorialScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const List<_FeatureCardItem> _features = [
    _FeatureCardItem(
      title: 'Create Notes',
      description:
          'Easily create notes using multiple input methods like capture, audio recording, or file upload.',
      icon: Icons.note_add_outlined,
    ),
    _FeatureCardItem(
      title: 'Audio to Notes',
      description:
          'Automatically converts recorded lecture audio into structured notes.',
      icon: Icons.mic_none_rounded,
    ),
    _FeatureCardItem(
      title: 'Reminders',
      description:
          'Helps you stay on track by sending timely revision notifications.',
      icon: Icons.alarm_outlined,
    ),
    _FeatureCardItem(
      title: 'Edit Notes',
      description:
          'Allows you to update and refine your notes anytime.',
      icon: Icons.edit_note_outlined,
    ),
    _FeatureCardItem(
      title: 'AI Summarization',
      description:
          'Generates concise summaries to quickly understand lengthy content.',
      icon: Icons.auto_awesome_outlined,
    ),
    _FeatureCardItem(
      title: 'Smart Search',
      description:
          'Quickly finds your notes using keywords through the library search.',
      icon: Icons.search_rounded,
    ),
    _FeatureCardItem(
      title: 'Secure Storage',
      description:
          'Keeps your data safe with reliable and secure storage mechanisms.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _currentIndex == _features.length - 1;

  Future<void> _goToPage(int index) {
    return _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Guide'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _features.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(22),
                      decoration: AppDecorations.card(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              feature.icon,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            feature.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            feature.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Feature ${index + 1} of ${_features.length}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _features.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.primary
                          : AppColors.primaryLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex == 0
                          ? null
                          : () => _goToPage(_currentIndex - 1),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLast ? null : () => _goToPage(_features.length - 1),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isLast) {
                      Navigator.of(context).pop();
                    } else {
                      _goToPage(_currentIndex + 1);
                    }
                  },
                  style: AppButtonStyles.primary(),
                  child: Text(_isLast ? 'Finish' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCardItem {
  const _FeatureCardItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
