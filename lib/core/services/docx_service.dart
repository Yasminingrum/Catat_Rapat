import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meeting_model.dart';

/// Menghasilkan & membagikan file DOCX (Microsoft Word) notula rapat.
class DocxService {
  DocxService._();
  static final DocxService instance = DocxService._();

  static const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const _rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _paragraph(String text, {bool bold = false, int size = 22}) {
    final rPr = bold ? '<w:rPr><w:b/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr>'
        : '<w:rPr><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr>';
    return '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr><w:r>$rPr'
        '<w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>';
  }

  Uint8List _buildDocumentXml({required Meeting meeting, required Notula notula}) {
    final body = StringBuffer();
    body.write(_paragraph('NOTULA RAPAT', size: 18));
    body.write(_paragraph(meeting.title, bold: true, size: 32));
    body.write(_paragraph('Tanggal: ${meeting.date}   Waktu: ${meeting.time}   Durasi: ${meeting.duration}'));
    body.write(_paragraph('Peserta: ${meeting.participants.map((p) => p.displayName).join(', ')}'));
    body.write(_paragraph(''));

    body.write(_paragraph('I. PEMBAHASAN', bold: true, size: 26));
    body.write(_paragraph(notula.ringkasan));
    body.write(_paragraph(''));

    body.write(_paragraph('II. KEPUTUSAN RAPAT', bold: true, size: 26));
    for (final e in notula.keputusan.asMap().entries) {
      body.write(_paragraph('${e.key + 1}. ${e.value.text}'));
    }
    body.write(_paragraph(''));

    body.write(_paragraph('III. TINDAK LANJUT', bold: true, size: 26));
    for (final e in notula.actionItems.asMap().entries) {
      final a = e.value;
      body.write(_paragraph('${e.key + 1}. ${a.text} — ${a.assignee} (${a.deadline})'));
    }
    body.write(_paragraph(''));
    body.write(_paragraph(''));

    body.write(_paragraph('Notulis: ______________________'));
    body.write(_paragraph(''));
    body.write(_paragraph('Pimpinan Rapat: ______________________'));

    final xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$body<w:sectPr/></w:body></w:document>';
    return utf8.encode(xml);
  }

  Future<Uint8List> _buildDocxBytes({required Meeting meeting, required Notula notula}) async {
    final archive = Archive();
    archive.addFile(ArchiveFile.bytes('[Content_Types].xml', utf8.encode(_contentTypes)));
    archive.addFile(ArchiveFile.bytes('_rels/.rels', utf8.encode(_rootRels)));
    archive.addFile(ArchiveFile.bytes('word/document.xml', _buildDocumentXml(meeting: meeting, notula: notula)));
    final bytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(bytes);
  }

  String _fileName(Meeting meeting) {
    final safeTitle = meeting.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return 'Notula ${safeTitle.isNotEmpty ? safeTitle : meeting.id}.docx';
  }

  /// Membuat DOCX notula lalu membuka dialog berbagi/simpan bawaan sistem.
  Future<void> shareNotulaDocx({
    required Meeting meeting,
    required Notula notula,
  }) async {
    final bytes = await _buildDocxBytes(meeting: meeting, notula: notula);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_fileName(meeting)}';
    await File(path).writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
      subject: 'Notula Rapat: ${meeting.title}',
    ));
  }
}
