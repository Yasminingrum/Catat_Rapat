import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/meeting_model.dart';

/// Layanan notifikasi lokal CatatRapat.
///
/// Menangani dua jenis notifikasi:
/// - "Notifikasi Ringkasan Selesai": notifikasi instan saat AI selesai
///   membuat notula dari sebuah rapat.
/// - "Reminder Action Item": notifikasi terjadwal pada hari jatuh tempo
///   tindak lanjut yang belum selesai.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'catatrapat_default';
  static const _channelName = 'CatatRapat';
  static const _channelDescription = 'Notifikasi pengingat dan status CatatRapat';

  static const _bulanIndo = {
    'januari': 1, 'februari': 2, 'maret': 3, 'april': 4,
    'mei': 5, 'juni': 6, 'juli': 7, 'agustus': 8,
    'september': 9, 'oktober': 10, 'november': 11, 'desember': 12,
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Biarkan default (UTC) bila zona waktu tidak tersedia di platform.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));
  }

  /// Meminta izin notifikasi ke pengguna (Android 13+ & iOS).
  /// Mengembalikan `true` bila izin diberikan.
  Future<bool> requestPermission() async {
    await init();
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
        alert: true, badge: true, sound: true);

    if (android != null) return androidGranted ?? false;
    if (ios != null) return iosGranted ?? false;
    return true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Menampilkan notifikasi instan saat notula sebuah rapat selesai dibuat.
  Future<void> showSummaryReadyNotification({
    required String meetingId,
    required String meetingTitle,
  }) async {
    await init();
    await _plugin.show(
      _idForMeeting(meetingId),
      'Notula Siap',
      'Notula untuk "$meetingTitle" telah selesai dibuat.',
      _details,
    );
  }

  /// Menjadwalkan ulang reminder untuk seluruh action item sebuah rapat.
  ///
  /// Reminder hanya dijadwalkan untuk item yang masih [ActionStatus.pending]
  /// dan memiliki deadline berformat "<tanggal> <nama bulan>" (mis. "28 Mei")
  /// yang jatuh pada hari ini atau di masa depan.
  Future<void> scheduleActionItemReminders({
    required String meetingId,
    required String meetingTitle,
    required List<ActionItem> items,
  }) async {
    await init();
    for (final item in items) {
      final id = _idForActionItem(meetingId, item.id);
      await _plugin.cancel(id);
      if (item.status == ActionStatus.done) continue;

      final due = _parseDeadline(item.deadline);
      if (due == null) continue;

      await _plugin.zonedSchedule(
        id,
        'Pengingat Tindak Lanjut',
        '${item.text} — jatuh tempo hari ini ($meetingTitle)',
        tz.TZDateTime.from(due, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Membatalkan seluruh reminder action item milik sebuah rapat.
  Future<void> cancelActionItemReminders({
    required String meetingId,
    required List<int> itemIds,
  }) async {
    await init();
    for (final itemId in itemIds) {
      await _plugin.cancel(_idForActionItem(meetingId, itemId));
    }
  }

  /// Membatalkan seluruh notifikasi terjadwal (reminder action item),
  /// dipanggil saat pengguna menonaktifkan "Reminder Action Item".
  Future<void> cancelAllScheduled() async {
    await init();
    await _plugin.cancelAll();
  }

  int _idForMeeting(String meetingId) => meetingId.hashCode & 0x7fffffff;

  int _idForActionItem(String meetingId, int itemId) =>
      ('$meetingId#$itemId').hashCode & 0x7fffffff;

  /// Parsing deadline berformat "<tanggal> <bulan>" (Bahasa Indonesia, tanpa
  /// tahun) menjadi [DateTime] jam 09:00 pada tahun berjalan. Mengembalikan
  /// `null` bila format tidak dikenali atau tanggal sudah lewat.
  DateTime? _parseDeadline(String deadline) {
    final parts = deadline.trim().toLowerCase().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final day = int.tryParse(parts[0]);
    final month = _bulanIndo[parts[1]];
    if (day == null || month == null) return null;

    final now = DateTime.now();
    DateTime date;
    try {
      date = DateTime(now.year, month, day, 9, 0);
    } catch (_) {
      return null;
    }
    if (date.isBefore(now)) return null;
    return date;
  }
}
