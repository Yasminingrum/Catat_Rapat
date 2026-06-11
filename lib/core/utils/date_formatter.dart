
abstract final class DateFormatter {
  static String formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  static String formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}d';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}j ${m}m';
  }

  static String formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  static String today() => formatDate(DateTime.now());
  static String nowTime() => formatTime(DateTime.now());

  /// Parse string hasil [formatDate], mis. "28 Mei 2026" → DateTime.
  static DateTime? parseDate(String s) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    final parts = s.trim().split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final monthIdx = months.indexOf(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || monthIdx == -1 || year == null) return null;
    return DateTime(year, monthIdx + 1, day);
  }
}
