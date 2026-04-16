import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/routes/app_routes.dart';
import 'package:smart_lecture_notes/widgets/custom_app_bar.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

/// Example: Implementing a feature card with navigation
/// This shows best practices for button navigation
class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? routeName;
  final VoidCallback? onTap;

  const FeatureCard({
    required this.title, required this.description, required this.icon, required this.color, Key? key,
    this.routeName,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (routeName != null) {
          // Use Navigator.of(context).pushNamed for clean navigation
          Navigator.of(context).pushNamed(routeName!);
        }
      },
      child: Container(
        decoration: AppDecorations.card(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Navigation Implementation
class NavigationDemoScreen extends StatelessWidget {
  const NavigationDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Smart Lecture Notes',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                decoration: AppDecorations.heroCard(),
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Student!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You have 12 lectures and 45 notes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(label: 'Lectures', value: '12'),
                        _StatCard(label: 'Notes', value: '45'),
                        _StatCard(label: 'Subjects', value: '8'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Capture Methods
              const Text(
                'Capture Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  FeatureCard(
                    title: 'Record Audio',
                    description: 'Record live lectures',
                    icon: Icons.mic,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.recordAudio,
                  ),
                  FeatureCard(
                    title: 'Camera Scan',
                    description: 'Scan board notes',
                    icon: Icons.camera_alt,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.smartCamera,
                  ),
                  FeatureCard(
                    title: 'File Upload',
                    description: 'Upload files and images',
                    icon: Icons.upload_file,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.captureNotes,
                  ),
                  FeatureCard(
                    title: 'My Notes',
                    description: 'View all saved notes',
                    icon: Icons.note,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.viewNotes,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Learning Tools
              const Text(
                'Learning Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  FeatureCard(
                    title: 'Practice Quiz',
                    description: 'Test your knowledge',
                    icon: Icons.quiz,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.practiceQuiz,
                  ),
                  FeatureCard(
                    title: 'Analytics',
                    description: 'Track progress',
                    icon: Icons.assessment,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.studyAnalytics,
                  ),
                  FeatureCard(
                    title: 'Revision Plan',
                    description: 'Spaced repetition',
                    icon: Icons.schedule,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.revisionReminder,
                  ),
                  FeatureCard(
                    title: 'Profile',
                    description: 'Your settings',
                    icon: Icons.person,
                    color: AppColors.primaryLight,
                    routeName: AppRoutes.profile,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget for stat cards
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label, required this.value, Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB8C5E0),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
