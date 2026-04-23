import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lecture_notes/services/revision_reminder_service.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class RevisionRemindersScreen extends StatefulWidget {
  const RevisionRemindersScreen({Key? key}) : super(key: key);

  @override
  State<RevisionRemindersScreen> createState() =>
      _RevisionRemindersScreenState();
}

class _RevisionRemindersScreenState extends State<RevisionRemindersScreen> {
  bool _remindersEnabled = true;
  String _reminderInterval = 'Every 7 days';
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _showAlarms = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _intervalOptions = [
    'Every 1 day',
    'Every 3 days',
    'Every 7 days',
    'Every 14 days',
    'Every 30 days',
  ];

  final Map<String, int> _intervalDaysMap = const {
    'Every 1 day': 1,
    'Every 3 days': 3,
    'Every 7 days': 7,
    'Every 14 days': 14,
    'Every 30 days': 30,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await RevisionReminderService.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _remindersEnabled = settings.enabled;
      _notificationTime = settings.timeOfDay;
      _reminderInterval = _intervalDaysMap.entries
          .firstWhere(
            (entry) => entry.value == settings.intervalDays,
            orElse: () => const MapEntry('Every 7 days', 7),
          )
          .key;
      _isLoading = false;
    });
  }

  RevisionReminderSettings _buildSettings() {
    final intervalDays = _intervalDaysMap[_reminderInterval] ?? 7;
    return RevisionReminderSettings(
      enabled: _remindersEnabled,
      intervalDays: intervalDays,
      hour: _notificationTime.hour,
      minute: _notificationTime.minute,
    );
  }

  Future<void> _persistAndSchedule({String? successMessage}) async {
    setState(() => _isSaving = true);
    final settings = _buildSettings();

    try {
      await RevisionReminderService.saveSettings(settings);
      await RevisionReminderService.scheduleReminders(settings);
      if (!mounted) return;
      if (successMessage != null && successMessage.isNotEmpty) {
        Get.snackbar(
          'Settings Saved',
          successMessage,
          backgroundColor: AppColors.primary.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Reminder Error',
        'Failed to update reminders: $e',
        backgroundColor: AppColors.primary.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Revision Reminders',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enable Reminders Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.card(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Reminders',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get notified to review your notes',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _remindersEnabled,
                        onChanged: (value) {
                          setState(() => _remindersEnabled = value);
                          _persistAndSchedule(
                            successMessage: value
                                ? 'Reminders enabled and scheduled.'
                                : 'Reminders disabled.',
                          );
                        },
                        activeThumbColor: AppColors.primary,
                        activeTrackColor:
                            AppColors.primaryLight.withOpacity(0.3),
                        inactiveThumbColor: AppColors.border,
                        inactiveTrackColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reminder Interval Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reminder Interval',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: AppDecorations.card(),
                    child: DropdownButton<String>(
                      value: _reminderInterval,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      items: _intervalOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _reminderInterval = newValue);
                          _persistAndSchedule(
                            successMessage: 'Reminders will come $newValue.',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notification Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                      );
                      if (pickedTime != null) {
                        setState(() => _notificationTime = pickedTime);
                        _persistAndSchedule(
                          successMessage:
                              'Notifications will arrive at ${pickedTime.format(context)}.',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: AppDecorations.card(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: AppColors.primaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _notificationTime.format(context),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.card(
                  color: AppColors.primaryLight.withOpacity(0.08),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spaced Repetition Learning',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Research shows that reviewing material at increasing intervals improves long-term retention. Our AI will remind you to review notes at optimal times for maximum learning efficiency.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Alarms Section (shown when enabled)
              if (_remindersEnabled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Alarms',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showAlarms = !_showAlarms);
                          },
                          child: Icon(
                            _showAlarms
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    if (_showAlarms) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppDecorations.card(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alarm set for ${_notificationTime.format(context)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _reminderInterval,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Edit'),
                                      onTap: () {
                                        Get.snackbar(
                                          'Edit Alarm',
                                          'Editing alarm settings...',
                                          backgroundColor:
                                              AppColors.primary.withOpacity(0.9),
                                          colorText: Colors.white,
                                          duration:
                                              const Duration(seconds: 1),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      onTap: () {
                                        Get.snackbar(
                                          'Alarm Deleted',
                                          'Alarm has been removed',
                                          backgroundColor:
                                              AppColors.primary.withOpacity(0.9),
                                          colorText: Colors.white,
                                          duration:
                                              const Duration(seconds: 1),
                                        );
                                      },
                                    ),
                                  ],
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Save Settings Button
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _persistAndSchedule(
                        successMessage: 'Revision reminder settings updated.',
                      ),
              style: AppButtonStyles.primary(radius: 14),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
