import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Menulis stream PCM16 mentah ke file `.wav` secara incremental.
///
/// [writeChunk] tidak perlu di-await oleh caller — operasi-operasi di-chain
/// secara internal sehingga tidak ada dua [RandomAccessFile.writeFrom] yang
/// berjalan bersamaan (yang akan melempar "Async operation already in progress").
class WavWriter {
  WavWriter(this.path, {this.sampleRate = 24000, this.numChannels = 1});

  final String path;
  final int sampleRate;
  final int numChannels;
  static const _bitsPerSample = 16;

  RandomAccessFile? _file;
  int _dataLength = 0;
  // Rantai Future yang menjamin setiap write selesai sebelum write berikutnya.
  Future<void> _queue = Future.value();

  Future<void> open() async {
    _file = await File(path).open(mode: FileMode.write);
    await _file!.writeFrom(Uint8List(44)); // placeholder header
  }

  // Tidak perlu di-await; hasil di-queue secara otomatis.
  void writeChunk(Uint8List bytes) {
    _queue = _queue.then((_) async {
      final file = _file;
      if (file == null) return;
      await file.writeFrom(bytes);
      _dataLength += bytes.length;
    });
  }

  Future<void> close() async {
    await _queue; // tunggu semua write selesai sebelum tulis header
    final file = _file;
    if (file == null) return;
    await file.setPosition(0);
    await file.writeFrom(_buildHeader());
    await file.close();
    _file = null;
  }

  Uint8List _buildHeader() {
    final byteRate = sampleRate * numChannels * _bitsPerSample ~/ 8;
    final blockAlign = numChannels * _bitsPerSample ~/ 8;
    final b = BytesBuilder();
    b.add(ascii.encode('RIFF'));
    b.add(_uint32(36 + _dataLength));
    b.add(ascii.encode('WAVE'));
    b.add(ascii.encode('fmt '));
    b.add(_uint32(16));
    b.add(_uint16(1)); // PCM
    b.add(_uint16(numChannels));
    b.add(_uint32(sampleRate));
    b.add(_uint32(byteRate));
    b.add(_uint16(blockAlign));
    b.add(_uint16(_bitsPerSample));
    b.add(ascii.encode('data'));
    b.add(_uint32(_dataLength));
    return b.toBytes();
  }

  Uint8List _uint16(int v) =>
      (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();

  Uint8List _uint32(int v) =>
      (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
}
