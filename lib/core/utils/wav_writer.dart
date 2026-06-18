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

  /// Downsample WAV dari [srcRate] ke [dstRate] menggunakan interpolasi linear.
  /// Mengembalikan path file baru yang sudah di-downsample.
  /// Jika file sudah cukup kecil atau rate sama, mengembalikan [srcPath].
  static Future<String> downsample(
    String srcPath, {
    int dstRate = 16000,
  }) async {
    final srcFile = File(srcPath);
    final bytes = await srcFile.readAsBytes();
    if (bytes.length < 44) return srcPath;

    final header = ByteData.sublistView(bytes, 0, 44);
    final srcRate = header.getUint32(24, Endian.little);
    if (srcRate <= dstRate) return srcPath;

    const bytesPerSample = 2; // 16-bit PCM
    final dataSize = bytes.length - 44;
    final numSamples = dataSize ~/ bytesPerSample;
    final ratio = srcRate / dstRate;
    final outCount = (numSamples / ratio).floor();

    final srcData = ByteData.sublistView(bytes, 44);
    final outData = ByteData(outCount * bytesPerSample);

    for (var i = 0; i < outCount; i++) {
      final srcPos = i * ratio;
      final idx = srcPos.floor();
      final frac = srcPos - idx;
      final s0 = srcData.getInt16(idx * bytesPerSample, Endian.little);
      final s1 = idx + 1 < numSamples
          ? srcData.getInt16((idx + 1) * bytesPerSample, Endian.little)
          : s0;
      final sample =
          (s0 * (1.0 - frac) + s1 * frac).round().clamp(-32768, 32767);
      outData.setInt16(i * bytesPerSample, sample, Endian.little);
    }

    final dstPath = srcPath.replaceAll('.wav', '_ds.wav');
    final writer = WavWriter(dstPath, sampleRate: dstRate, numChannels: 1);
    await writer.open();
    writer.writeChunk(outData.buffer.asUint8List());
    await writer.close();
    return dstPath;
  }
}
