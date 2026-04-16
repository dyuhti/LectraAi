import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final List<String> _intervalOptions = [
    'Every 1 day',
    'Every 3 days',
    'Every 7 days',
    'Every 14 days',
    'Every 30 days',
  ];

  @override
  Widget build(BuildContext context) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enable Reminders',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get notified to review your notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
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
                          if (value) {
                            Get.snackbar(
                              'Reminders Enabled',
                              'You will receive revision notifications',
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.9),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          }
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
                          Get.snackbar(
                            'Interval Updated',
                            'Reminders will come $newValue',
                            backgroundColor:
                                AppColors.primary.withOpacity(0.9),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
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
                        Get.snackbar(
                          'Time Updated',
                          'Notifications will arrive at ${pickedTime.format(context)}',
                            backgroundColor:
                                AppColors.primary.withOpacity(0.9),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spaced Repetition Learning',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Research shows that reviewing material at increasing intervals improves long-term retention. Our AI will remind you to review notes at optimal times for maximum learning efficiency.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
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
                                      style: TextStyle(
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
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 12,
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
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Get.snackbar(
                'Settings Saved',
                'Revision reminder settings updated',
                backgroundColor: AppColors.primary.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: AppButtonStyles.primary(radius: 14),
            child: const Text(
              'Save Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
