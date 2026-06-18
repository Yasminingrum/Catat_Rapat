import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PendingRecording {
  PendingRecording({
    required this.filePath,
    required this.title,
    this.agenda,
    required this.durationSeconds,
    required this.createdAt,
    this.meetingId,
    this.uploadedAudioPath,
  });

  final String filePath;
  final String title;
  final String? agenda;
  final int durationSeconds;
  final DateTime createdAt;
  final String? meetingId;
  final String? uploadedAudioPath;

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'title': title,
        'agenda': agenda,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
        'meetingId': meetingId,
        'uploadedAudioPath': uploadedAudioPath,
      };

  factory PendingRecording.fromJson(Map<String, dynamic> j) =>
      PendingRecording(
        filePath: j['filePath'] as String,
        title: j['title'] as String,
        agenda: j['agenda'] as String?,
        durationSeconds: j['durationSeconds'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        meetingId: j['meetingId'] as String?,
        uploadedAudioPath: j['uploadedAudioPath'] as String?,
      );
}

class PendingRecordingService {
  PendingRecordingService._();
  static final instance = PendingRecordingService._();

  static const _key = 'pending_recordings';

  Future<List<PendingRecording>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final list = <PendingRecording>[];
    for (final s in raw) {
      try {
        final rec =
            PendingRecording.fromJson(jsonDecode(s) as Map<String, dynamic>);
        if (await File(rec.filePath).exists()) list.add(rec);
      } catch (_) {}
    }
    return list;
  }

  Future<void> save(PendingRecording rec) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try {
        final existing =
            PendingRecording.fromJson(jsonDecode(s) as Map<String, dynamic>);
        return existing.filePath == rec.filePath;
      } catch (_) {
        return false;
      }
    });
    raw.add(jsonEncode(rec.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> remove(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try {
        final existing =
            PendingRecording.fromJson(jsonDecode(s) as Map<String, dynamic>);
        return existing.filePath == filePath;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, raw);
  }
}
