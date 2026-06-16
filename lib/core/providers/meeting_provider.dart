import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_model.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

// ── Meeting List Provider ─────────────────────────────────────

class MeetingListNotifier extends StateNotifier<AsyncValue<List<Meeting>>> {
  MeetingListNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
    _ref.listen(authProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) load();
    });
  }

  final Ref _ref;
  final _supa = SupabaseService.instance;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _supa.getMeetings());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => load();

  Future<void> deleteMeeting(String id) async {
    final prev = state.value ?? [];
    state = AsyncValue.data(prev.where((m) => m.id != id).toList());
    try {
      await _supa.deleteMeeting(id);
    } catch (_) {
      state = AsyncValue.data(prev); // rollback
    }
  }

  Future<void> deleteAllMeetings() async {
    await _supa.deleteAllMeetings();
    state = const AsyncValue.data([]);
  }

  Future<void> toggleStar(String id) async {
    final prev = state.value ?? [];
    final matches = prev.where((m) => m.id == id);
    if (matches.isEmpty) return;
    final newValue = !matches.first.isStarred;
    state = AsyncValue.data(prev.map((m) =>
        m.id == id ? m.copyWith(isStarred: newValue) : m).toList());
    try {
      await _supa.updateMeeting(id, {'is_starred': newValue});
    } catch (_) {
      state = AsyncValue.data(prev); // rollback
    }
  }
}

final meetingListProvider =
    StateNotifierProvider<MeetingListNotifier, AsyncValue<List<Meeting>>>(
        (ref) => MeetingListNotifier(ref));

// ── Visible Meetings Provider (menerapkan Retensi Rekaman) ────

final visibleMeetingsProvider = Provider<AsyncValue<List<Meeting>>>((ref) {
  final meetingsAsync = ref.watch(meetingListProvider);
  final retention = ref.watch(settingsProvider).retention;

  return meetingsAsync.whenData((meetings) {
    final retentionDays = switch (retention) {
      RetentionPeriod.days30 => 30,
      RetentionPeriod.days90 => 90,
      RetentionPeriod.year1 => 365,
      RetentionPeriod.forever => null,
    };
    if (retentionDays == null) return meetings;

    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return meetings.where((m) {
      final date = DateFormatter.parseDate(m.date);
      return date == null || !date.isBefore(cutoff);
    }).toList();
  });
});

// ── Single Meeting Provider ───────────────────────────────────

final meetingProvider = FutureProvider.family<Meeting?, String>((ref, id) async {
  final list = ref.watch(meetingListProvider).value ?? [];
  final found = list.where((m) => m.id == id);
  if (found.isNotEmpty) return found.first;
  try {
    return await SupabaseService.instance.getMeeting(id);
  } catch (_) { return null; }
});

// ── Notula Provider ───────────────────────────────────────────

class NotulaNotifier extends StateNotifier<Notula?> {
  NotulaNotifier(this._ref, this._meetingId) : super(null) {
    _load();
  }

  final Ref _ref;
  final String _meetingId;

  Future<void> _load() async {
    // Gunakan mock untuk development
    if (_meetingId == '1') {
      state = MockData.sampleNotula;
    } else {
      final notula = await SupabaseService.instance.getNotula(_meetingId);
      state = notula ?? Notula(ringkasan: '', keputusan: [], actionItems: []);
    }
  }

  Future<void> save(Notula notula) async {
    state = notula;
    await SupabaseService.instance.saveNotula(_meetingId, notula);
    await _syncActionReminders(notula.actionItems);
  }

  /// Menyinkronkan reminder action item dengan setting "Reminder Action Item"
  /// dan status terkini setiap item.
  Future<void> _syncActionReminders(List<ActionItem> items) async {
    if (!_ref.read(settingsProvider).notifActionReminder) {
      await NotificationService.instance.cancelActionItemReminders(
          meetingId: _meetingId, itemIds: items.map((a) => a.id).toList());
      return;
    }
    final meetingTitle = _ref.read(meetingProvider(_meetingId)).value?.title ?? '';
    await NotificationService.instance.scheduleActionItemReminders(
        meetingId: _meetingId, meetingTitle: meetingTitle, items: items);
  }

  void updateRingkasan(String text) {
    if (state == null) return;
    state = state!.copyWith(ringkasan: text);
  }

  void addKeputusan(String text) {
    if (state == null) return;
    final items = List<KeputusanItem>.from(state!.keputusan)
      ..add(KeputusanItem(id: DateTime.now().millisecondsSinceEpoch, text: text));
    state = state!.copyWith(keputusan: items);
  }

  void removeKeputusan(int id) {
    if (state == null) return;
    state = state!.copyWith(keputusan: state!.keputusan.where((k) => k.id != id).toList());
  }

  void addActionItem(ActionItem item) {
    if (state == null) return;
    final items = List<ActionItem>.from(state!.actionItems)..add(item);
    state = state!.copyWith(actionItems: items);
  }

  void removeActionItem(int id) {
    if (state == null) return;
    state = state!.copyWith(actionItems: state!.actionItems.where((a) => a.id != id).toList());
  }

  Future<void> toggleActionStatus(int id) async {
    if (state == null) return;
    final items = state!.actionItems.map((a) {
      if (a.id == id) a.status = a.status == ActionStatus.pending ? ActionStatus.done : ActionStatus.pending;
      return a;
    }).toList();
    final updated = state!.copyWith(actionItems: items);
    state = updated;
    // Persist immediately so the status survives navigation and appears in exports.
    if (_meetingId != '1') {
      await SupabaseService.instance.saveNotula(_meetingId, updated);
    }
    await _syncActionReminders(items);
  }
}

final notulaProvider = StateNotifierProvider.family<NotulaNotifier, Notula?, String>(
    (ref, meetingId) => NotulaNotifier(ref, meetingId));

// ── Transcript Provider ───────────────────────────────────────

final transcriptProvider = FutureProvider.family<List<TranscriptLine>, String>((ref, meetingId) async {
  if (meetingId == '1') return MockData.sampleTranscript;
  return SupabaseService.instance.getTranscript(meetingId);
});
