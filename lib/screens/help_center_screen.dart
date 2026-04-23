import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedIndex;

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I create a note?',
      answer:
          'Tap Start on the home screen and choose your preferred option: Capture, Record, or Upload to create a note.',
      icon: Icons.note_add_outlined,
    ),
    _FaqItem(
      question: 'How can I record notes?',
      answer:
          'Tap Start Now and select Record Lecture Audio to seamlessly convert audio into notes.',
      icon: Icons.mic_none_rounded,
    ),
    _FaqItem(
      question: 'How do I set a reminder?',
      answer:
          'Go to Settings and select Revision Reminders to schedule notifications.',
      icon: Icons.alarm_outlined,
    ),
    _FaqItem(
      question: 'Can I edit my notes?',
      answer:
          'Yes, open any note and use the edit option to make changes anytime.',
      icon: Icons.edit_note_outlined,
    ),
    _FaqItem(
      question: 'How does AI summarization work?',
      answer:
          'Open a note and tap the Summarize option to generate a concise summary automatically.',
      icon: Icons.auto_awesome_outlined,
    ),
    _FaqItem(
      question: 'Can I search my notes?',
      answer:
          'Use the search bar in the Library section to quickly find your notes.',
      icon: Icons.search_rounded,
    ),
    _FaqItem(
      question: 'Is my data secure?',
      answer:
          'Yes, your data is securely stored and protected using encryption.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  void _toggle(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecorations.heroCard(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find quick answers or open the App Guide to explore what each SmartNotes feature does.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _faqs.length,
            (index) => _FaqAccordionCard(
              item: _faqs[index],
              expanded: _expandedIndex == index,
              onTap: () => _toggle(index),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'App Guide',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swipe through a quick feature overview of note creation, audio conversion, reminders, AI tools, search, and secure storage.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.appGuide);
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Open App Guide'),
                    style: AppButtonStyles.primary(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqAccordionCard extends StatelessWidget {
  const _FaqAccordionCard({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(
        color: expanded ? const Color(0xFFF8FAFF) : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppDecorations.iconContainer(radius: 10),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    heightFactor: expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, left: 2, right: 2),
                      child: Text(
                        item.answer,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });

  final String question;
  final String answer;
  final IconData icon;
}
