import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:smart_lecture_notes/models/note.dart';
import 'package:smart_lecture_notes/models/progress.dart';
import 'package:smart_lecture_notes/providers/note_provider.dart';
import 'package:smart_lecture_notes/providers/progress_provider.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class StudyDashboardScreen extends StatefulWidget {
  const StudyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudyDashboardScreen> createState() => _StudyDashboardScreenState();
}

class _StudyDashboardScreenState extends State<StudyDashboardScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NoteProvider>().loadNotes();
      context.read<ProgressProvider>().refreshProgress();
    });
  }

  List<double> _buildWeeklyData(List<Note> notes) {
    final today = DateTime.now();
    final values = List<double>.filled(7, 0);

    for (final note in notes) {
      final diff = today.difference(note.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        final index = (today.weekday - 1 - diff) % 7;
        final safeIndex = index < 0 ? index + 7 : index;
        values[safeIndex] += 1;
      }
    }

    return values;
  }

  String _formatStudyHours(List<Note> notes) {
    if (notes.isEmpty) {
      return '0';
    }

    final minutes = notes.length * 18;
    final hours = minutes / 60;
    return hours.toStringAsFixed(hours >= 10 ? 0 : 1);
  }

  String _formatTodayProgress(DailyProgress progress) {
    final todayCount = progress.notesCreated;

    if (todayCount == 0) {
      return 'No notes created today';
    }

    return '$todayCount note${todayCount == 1 ? '' : 's'} created today';
  }

  List<double> _buildWeeklyDataFromHistory(List<DailyProgress> history) {
    final values = List<double>.filled(7, 0);
    final today = DateTime.now();

    // Map history to the last 7 days
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final record = history.firstWhere(
        (h) => h.date == dateStr,
        orElse: () => DailyProgress.empty(),
      );

      // Map back to Mon-Sun index (0-6)
      final dayIndex = (date.weekday - 1) % 7;
      values[dayIndex] = record.notesCreated.toDouble();
    }

    return values;
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
          'Study Dashboard',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer2<NoteProvider, ProgressProvider>(
        builder: (context, noteProvider, progressProvider, _) {
              if (progressProvider.isLoading && noteProvider.notes.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final notes = noteProvider.notes;
              final progress = progressProvider.progress;
              final history = progressProvider.history;

              final weeklyData = _buildWeeklyDataFromHistory(history);
              final totalNotes = notes.length;
              final studyHours = _formatStudyHours(notes);
              final todayStatus = _formatTodayProgress(progress);
              final maxValue = weeklyData.fold<double>(
                  0, (max, value) => value > max ? value : max);

          return RefreshIndicator(
            onRefresh: () async {
              await noteProvider.loadNotes();
              await progressProvider.refreshProgress();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.note_outlined,
                            label: 'Total Notes',
                            value: totalNotes.toString(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.access_time,
                            label: 'Study Hours',
                            value: studyHours,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      todayStatus,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Weekly Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppDecorations.card(),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(weeklyData.length, (index) {
                                final value = weeklyData[index];
                                final normalized = maxValue == 0 ? 0.0 : value / maxValue;
                                final barHeight = 12 + (normalized * 120);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 250),
                                          child: Text(
                                            value.toStringAsFixed(0),
                                            key: ValueKey('$index-$value'),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 350),
                                          curve: Curves.easeOutCubic,
                                          width: 18,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primaryLight,
                                                AppColors.primary,
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _days[index],
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            noteProvider.notes.isEmpty
                                ? 'No activity yet'
                                : 'Study activity updates as you save notes',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppDecorations.iconContainer(radius: 10),
                child: Icon(
                  icon,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
