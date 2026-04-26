class DailyProgress {
  final String date;
  final int notesCreated;
  final int audioRecorded;
  final int quizzesGenerated;
  final int studyTime;
  final int progressScore;

  DailyProgress({
    required this.date,
    required this.notesCreated,
    required this.audioRecorded,
    required this.quizzesGenerated,
    required this.studyTime,
    this.progressScore = 0,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: json['date'] ?? '',
      notesCreated: json['notesCreated'] ?? 0,
      audioRecorded: json['audioRecorded'] ?? 0,
      quizzesGenerated: json['quizzesGenerated'] ?? 0,
      studyTime: json['studyTime'] ?? 0,
      progressScore: json['progressScore'] ?? 0,
    );
  }

  factory DailyProgress.empty() {
    return DailyProgress(
      date: '',
      notesCreated: 0,
      audioRecorded: 0,
      quizzesGenerated: 0,
      studyTime: 0,
      progressScore: 0,
    );
  }
}
