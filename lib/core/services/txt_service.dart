import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meeting_model.dart';

/// Menghasilkan & membagikan file teks polos (.txt) notula rapat.
class TxtService {
  TxtService._();
  static final TxtService instance = TxtService._();

  String _buildContent({required Meeting meeting, required Notula notula}) {
    final buffer = StringBuffer()
      ..writeln('NOTULA RAPAT')
      ..writeln(meeting.title)
      ..writeln('Tanggal: ${meeting.date}   Waktu: ${meeting.time}   Durasi: ${meeting.duration}')
      ..writeln('Peserta: ${meeting.participants.map((p) => p.displayName).join(', ')}')
      ..writeln()
      ..writeln('I. PEMBAHASAN')
      ..writeln(notula.ringkasan)
      ..writeln()
      ..writeln('II. KEPUTUSAN RAPAT');
    for (final e in notula.keputusan.asMap().entries) {
      buffer.writeln('${e.key + 1}. ${e.value.text}');
    }
    buffer
      ..writeln()
      ..writeln('III. TINDAK LANJUT');
    for (final e in notula.actionItems.asMap().entries) {
      final a = e.value;
      final checkbox = a.status == ActionStatus.done ? '[x]' : '[ ]';
      buffer.writeln('${e.key + 1}. $checkbox ${a.text} -> ${a.assignee} (${a.deadline})');
    }
    buffer
      ..writeln()
      ..writeln('Notulis: ______________________')
      ..writeln()
      ..writeln('Pimpinan Rapat: ______________________');
    return buffer.toString();
  }

  String _fileName(Meeting meeting) {
    final safeTitle = meeting.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return 'Notula ${safeTitle.isNotEmpty ? safeTitle : meeting.id}.txt';
  }

  /// Membuat file TXT notula lalu membuka dialog berbagi/simpan bawaan sistem.
  Future<void> shareNotulaTxt({
    required Meeting meeting,
    required Notula notula,
  }) async {
    final content = _buildContent(meeting: meeting, notula: notula);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_fileName(meeting)}';
    await File(path).writeAsString(content, encoding: utf8);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: 'text/plain')],
      subject: 'Notula Rapat: ${meeting.title}',
    ));
  }
}
