import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Meeting {
  const Meeting({
    required this.id, required this.title, required this.date,
    required this.time, required this.duration,
    required this.participants, required this.status,
    this.hasTranscript = false, this.hasNotula = false,
    this.hasAudio = false, this.isStarred = false, this.agenda, this.audioPath,
  });

  final String id, title, date, time, duration;
  final List<Participant> participants;
  final MeetingStatus status;
  final bool hasTranscript, hasNotula, hasAudio, isStarred;
  final String? agenda, audioPath;

  Meeting copyWith({
    String? title, String? agenda, MeetingStatus? status,
    bool? hasTranscript, bool? hasNotula, bool? hasAudio, bool? isStarred, String? audioPath,
  }) => Meeting(
    id: id, title: title ?? this.title, date: date, time: time, duration: duration,
    participants: participants, status: status ?? this.status,
    hasTranscript: hasTranscript ?? this.hasTranscript,
    hasNotula: hasNotula ?? this.hasNotula,
    hasAudio: hasAudio ?? this.hasAudio,
    isStarred: isStarred ?? this.isStarred,
    agenda: agenda ?? this.agenda, audioPath: audioPath ?? this.audioPath,
  );

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
    id: j['id'] as String, title: j['title'] as String,
    date: j['date'] as String, time: j['time'] as String,
    duration: j['duration'] as String? ?? '0m',
    participants: (j['participants'] as List<dynamic>? ?? [])
        .map((p) => Participant.fromJson(p as Map<String, dynamic>)).toList(),
    status: MeetingStatus.values.firstWhere(
        (e) => e.name == (j['status'] ?? 'draft'), orElse: () => MeetingStatus.draft),
    hasTranscript: j['has_transcript'] as bool? ?? false,
    hasNotula: j['has_notula'] as bool? ?? false,
    hasAudio: j['has_audio'] as bool? ?? false,
    isStarred: j['is_starred'] as bool? ?? false,
    agenda: j['agenda'] as String?,
    audioPath: j['audio_path'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'date': date, 'time': time, 'duration': duration,
    'participants': participants.map((p) => p.toJson()).toList(),
    'status': status.name, 'has_transcript': hasTranscript,
    'has_notula': hasNotula, 'has_audio': hasAudio, 'is_starred': isStarred,
    'agenda': agenda, 'audio_path': audioPath,
  };
}

enum MeetingStatus { draft, final_ }

class Participant {
  const Participant({
    required this.id, required this.label, required this.name,
    required this.color, required this.colorBg,
  });

  final String id, label, name;
  final Color color, colorBg;

  String get displayName => name.isNotEmpty ? name : label;

  factory Participant.fromJson(Map<String, dynamic> j) {
    final idx = int.tryParse((j['id'] as String? ?? 'S1').replaceAll('S', '')) ?? 1;
    return Participant(
      id: j['id'] as String, label: j['label'] as String? ?? 'Suara $idx',
      name: j['name'] as String? ?? '',
      color: AppColors.speakerColor(idx - 1),
      colorBg: AppColors.speakerBg(idx - 1),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'name': name};

  Participant copyWith({String? name}) =>
      Participant(id: id, label: label, name: name ?? this.name, color: color, colorBg: colorBg);
}

class TranscriptLine {
  const TranscriptLine({
    required this.timestamp, required this.speakerId,
    required this.speaker, required this.text,
  });
  final String timestamp, speakerId, speaker, text;

  factory TranscriptLine.fromJson(Map<String, dynamic> j) => TranscriptLine(
    timestamp: j['timestamp'] as String, speakerId: j['speaker_id'] as String,
    speaker: j['speaker'] as String, text: j['text'] as String,
  );
}

class Notula {
  Notula({required this.ringkasan, required this.keputusan, required this.actionItems});

  String ringkasan;
  List<KeputusanItem> keputusan;
  List<ActionItem> actionItems;

  Notula copyWith({String? ringkasan, List<KeputusanItem>? keputusan, List<ActionItem>? actionItems}) =>
      Notula(
        ringkasan: ringkasan ?? this.ringkasan,
        keputusan: keputusan ?? this.keputusan,
        actionItems: actionItems ?? this.actionItems,
      );

  factory Notula.fromJson(Map<String, dynamic> j) => Notula(
    ringkasan: j['ringkasan'] as String? ?? '',
    keputusan: (j['keputusan'] as List<dynamic>? ?? [])
        .map((k) => KeputusanItem.fromJson(k as Map<String, dynamic>)).toList(),
    actionItems: (j['action_items'] as List<dynamic>? ?? [])
        .map((a) => ActionItem.fromJson(a as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'ringkasan': ringkasan,
    'keputusan': keputusan.map((k) => k.toJson()).toList(),
    'action_items': actionItems.map((a) => a.toJson()).toList(),
  };
}

class KeputusanItem {
  KeputusanItem({required this.id, required this.text});
  final int id;
  String text;

  factory KeputusanItem.fromJson(Map<String, dynamic> j) =>
      KeputusanItem(id: j['id'] as int, text: j['text'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class ActionItem {
  ActionItem({
    required this.id, required this.text,
    required this.assignee, required this.deadline,
    this.status = ActionStatus.pending,
  });
  final int id;
  String text, assignee, deadline;
  ActionStatus status;

  factory ActionItem.fromJson(Map<String, dynamic> j) => ActionItem(
    id: j['id'] as int, text: j['text'] as String,
    assignee: j['assignee'] as String? ?? '', deadline: j['deadline'] as String? ?? '',
    status: ActionStatus.values.firstWhere(
        (e) => e.name == (j['status'] ?? 'pending'), orElse: () => ActionStatus.pending),
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'assignee': assignee,
    'deadline': deadline, 'status': status.name,
  };
}

enum ActionStatus { pending, done }

// ── Mock data untuk development ─────────────────────────────
abstract final class MockData {
  static final List<Participant> defaultParticipants = [
    const Participant(id:'S1', label:'Suara 1', name:'Budi Santoso',
        color: AppColors.speaker1, colorBg: AppColors.speaker1Bg),
    const Participant(id:'S2', label:'Suara 2', name:'Andi Pratama',
        color: AppColors.speaker2, colorBg: AppColors.speaker2Bg),
    const Participant(id:'S3', label:'Suara 3', name:'Suhita Rahayu',
        color: AppColors.speaker3, colorBg: AppColors.speaker3Bg),
  ];

  static final List<Meeting> meetings = [
    Meeting(id:'1', title:'Rapat Bersama PT Suka Suka',
        date:'28 Mei 2026', time:'10:30', duration:'23m 45s',
        participants: defaultParticipants, status: MeetingStatus.final_,
        hasTranscript: true, hasNotula: true, hasAudio: true),
    Meeting(id:'2', title:'Review Sprint Q2',
        date:'27 Mei 2026', time:'09:00', duration:'45m 10s',
        participants: defaultParticipants.sublist(0,2), status: MeetingStatus.final_,
        hasNotula: true),
    Meeting(id:'3', title:'Rapat Bersama PT Uniku Triniti',
        date:'25 Mei 2026', time:'14:00', duration:'1j 05m',
        participants: defaultParticipants, status: MeetingStatus.draft),
    Meeting(id:'4', title:'Review Produk Mingguan',
        date:'24 Mei 2026', time:'13:00', duration:'38m 22s',
        participants: defaultParticipants, status: MeetingStatus.final_,
        hasNotula: true),
    Meeting(id:'5', title:'Status Pengerjaan Q2',
        date:'22 Mei 2026', time:'11:00', duration:'15m 44s',
        participants: defaultParticipants.sublist(0,2), status: MeetingStatus.final_),
  ];

  static final Notula sampleNotula = Notula(
    ringkasan: 'Rapat membahas evaluasi sprint sebelumnya dan perencanaan sprint baru. '
        'Tim berhasil menyelesaikan 8 dari 12 story points (67%), dengan kendala pada '
        'integrasi API payment gateway dari vendor pihak ketiga.',
    keputusan: [
      KeputusanItem(id:1, text:'Tim commit 13 story points untuk sprint Q2, termasuk 4 poin carry over.'),
      KeputusanItem(id:2, text:'Fitur notifikasi push menjadi prioritas utama sprint ini (5 story points).'),
      KeputusanItem(id:3, text:'Daily standup dilanjutkan setiap pagi pukul 09.00 WIB.'),
    ],
    actionItems: [
      ActionItem(id:1, text:'Follow up dokumentasi API ke vendor payment gateway', assignee:'Budi', deadline:'28 Mei'),
      ActionItem(id:2, text:'Estimasi teknis fitur push notification dan buat tiket Jira', assignee:'Andi', deadline:'30 Mei'),
      ActionItem(id:3, text:'Update sprint board dengan carry over dari sprint sebelumnya', assignee:'Suhita', deadline:'28 Mei'),
      ActionItem(id:4, text:'Kirim undangan daily standup ke seluruh tim', assignee:'Budi', deadline:'29 Mei'),
    ],
  );

  static final List<TranscriptLine> sampleTranscript = [
    const TranscriptLine(timestamp:'00:00:05', speakerId:'S1', speaker:'Budi Santoso',
        text:'Baik, kita mulai rapat hari ini dengan review sprint kemarin. Dari target 12 story points, berapa yang sudah selesai?'),
    const TranscriptLine(timestamp:'00:00:28', speakerId:'S2', speaker:'Andi Pratama',
        text:'Sudah selesai 8 dari 12 story points. Yang 4 masih terkendala di integrasi API payment gateway dari vendor.'),
    const TranscriptLine(timestamp:'00:00:52', speakerId:'S1', speaker:'Budi Santoso',
        text:'Oke. Estimasinya berapa hari lagi kalau dokumentasi dari vendor sudah lengkap?'),
    const TranscriptLine(timestamp:'00:01:10', speakerId:'S3', speaker:'Suhita Rahayu',
        text:'Kalau dokumennya lengkap, sekitar 2 hari pengerjaan. Kita perlu follow up langsung ke vendor hari ini.'),
  ];
}
