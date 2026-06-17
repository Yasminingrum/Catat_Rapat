import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/meeting_model.dart';

/// Menghasilkan & membagikan file PDF notula rapat.
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  Future<Uint8List> _buildPdfBytes({
    required Meeting meeting,
    required Notula notula,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      header: (ctx) => _buildHeader(meeting),
      footer: (ctx) => _buildFooter(ctx),
      build: (ctx) => [
        _buildMeetingInfo(meeting),
        pw.SizedBox(height: 24),
        _buildSection('I. PEMBAHASAN', _substituteNames(notula.ringkasan, meeting.participants)),
        pw.SizedBox(height: 16),
        _buildKeputusan(notula.keputusan),
        pw.SizedBox(height: 16),
        _buildActionItems(notula.actionItems),
        pw.SizedBox(height: 32),
        _buildSignature(),
      ],
    ));

    return pdf.save();
  }

  String _substituteNames(String text, List<Participant> participants) {
    var result = text;
    for (final p in participants) {
      if (p.name.isNotEmpty) result = result.replaceAll(p.label, p.name);
    }
    return result;
  }

  String _fileName(Meeting meeting) {
    final safeTitle = meeting.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return 'Notula ${safeTitle.isNotEmpty ? safeTitle : meeting.id}.pdf';
  }

  /// Membuat file PDF notula dan menyimpannya di direktori dokumen aplikasi.
  /// Mengembalikan path file yang tersimpan.
  Future<String> generateNotulaPdf({
    required Meeting meeting,
    required Notula notula,
  }) async {
    final bytes = await _buildPdfBytes(meeting: meeting, notula: notula);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_fileName(meeting)}';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  /// Membuat PDF notula lalu membuka dialog berbagi/simpan bawaan sistem
  /// (Drive, Files, WhatsApp, Email, dll).
  Future<void> shareNotulaPdf({
    required Meeting meeting,
    required Notula notula,
  }) async {
    final bytes = await _buildPdfBytes(meeting: meeting, notula: notula);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(meeting));
  }

  pw.Widget _buildHeader(Meeting meeting) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('NOTULA RAPAT', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text('CatatRapat', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#4F46E5'))),
      ]),
      pw.Divider(color: PdfColors.grey300),
    ],
  );

  pw.Widget _buildFooter(pw.Context ctx) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('Dibuat dengan CatatRapat', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
      pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
    ],
  );

  pw.Widget _buildMeetingInfo(Meeting meeting) => pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(meeting.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        _infoCell('TANGGAL', meeting.date),
        _infoCell('WAKTU', meeting.time),
        _infoCell('DURASI', meeting.duration),
      ]),
      pw.SizedBox(height: 8),
      pw.Text('PESERTA', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
      pw.Text(meeting.participants.map((p) => p.displayName).join(', ')),
    ]),
  );

  pw.Widget _infoCell(String label, String value) => pw.Expanded(child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
      pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
    ],
  ));

  pw.Widget _buildSection(String title, String content) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text(content, style: const pw.TextStyle(fontSize: 12, lineSpacing: 4)),
    ],
  );

  pw.Widget _buildKeputusan(List<KeputusanItem> items) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('II. KEPUTUSAN RAPAT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...items.asMap().entries.map((e) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${e.key + 1}. ', style: const pw.TextStyle(fontSize: 12)),
          pw.Expanded(child: pw.Text(e.value.text, style: const pw.TextStyle(fontSize: 12))),
        ]),
      )),
    ],
  );

  pw.Widget _buildActionItems(List<ActionItem> items) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('III. TINDAK LANJUT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...items.asMap().entries.map((e) {
        final isDone = e.value.status == ActionStatus.done;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: isDone ? const PdfColor(0.88, 0.98, 0.93) : PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('${e.key + 1}. ${e.value.text}',
                  style: pw.TextStyle(
                      fontSize: 12,
                      decoration: isDone ? pw.TextDecoration.lineThrough : null,
                      decorationColor: PdfColors.grey600)),
            ])),
            pw.SizedBox(width: 10),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: isDone ? const PdfColor(0.06, 0.72, 0.51) : PdfColors.grey400,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  isDone ? 'Selesai' : 'Pending',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (e.value.assignee.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(e.value.assignee,
                    style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#4F46E5'))),
              ],
              if (e.value.deadline.isNotEmpty)
                pw.Text(e.value.deadline,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ]),
          ]),
        );
      }),
    ],
  );

  pw.Widget _buildSignature() => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(children: [
        pw.SizedBox(height: 40),
        pw.Container(width: 120, height: 1, color: PdfColors.grey400),
        pw.Text('Notulis', style: const pw.TextStyle(fontSize: 11)),
      ]),
      pw.Column(children: [
        pw.SizedBox(height: 40),
        pw.Container(width: 120, height: 1, color: PdfColors.grey400),
        pw.Text('Pimpinan Rapat', style: const pw.TextStyle(fontSize: 11)),
      ]),
    ],
  );
}
