String buildStructuredText({
  required String title,
  required String content,
  required List<String> keyPoints,
}) {
  final buffer = StringBuffer();

  final cleanTitle = title.trim();
  final cleanContent = content.trim();
  final cleanKeyPoints = keyPoints
      .map((point) => point.trim())
      .where((point) => point.isNotEmpty)
      .toList();

  if (cleanTitle.isNotEmpty) {
    buffer.writeln('Title. $cleanTitle.');
    buffer.writeln();
  }

  if (cleanContent.isNotEmpty) {
    buffer.writeln('Now reading explanation.');
    buffer.writeln('Explanation. $cleanContent.');
    buffer.writeln();
  }

  if (cleanKeyPoints.isNotEmpty) {
    buffer.writeln('Now reading key points.');
    buffer.writeln('Key Points.');
    for (var index = 0; index < cleanKeyPoints.length; index++) {
      buffer.writeln('Point ${index + 1}. ${cleanKeyPoints[index]}.');
    }
  }

  return buffer.toString().trim();
}