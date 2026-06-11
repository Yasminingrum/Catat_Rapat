import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_model.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

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
}

final meetingListProvider =
    StateNotifierProvider<MeetingListNotifier, AsyncValue<List<Meeting>>>(
        (ref) => MeetingListNotifier(ref));

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
  NotulaNotifier(this._meetingId) : super(null) {
    _load();
  }

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

  void toggleActionStatus(int id) {
    if (state == null) return;
    final items = state!.actionItems.map((a) {
      if (a.id == id) a.status = a.status == ActionStatus.pending ? ActionStatus.done : ActionStatus.pending;
      return a;
    }).toList();
    state = state!.copyWith(actionItems: items);
  }
}

final notulaProvider = StateNotifierProvider.family<NotulaNotifier, Notula?, String>(
    (ref, meetingId) => NotulaNotifier(meetingId));

// ── Transcript Provider ───────────────────────────────────────

final transcriptProvider = FutureProvider.family<List<TranscriptLine>, String>((ref, meetingId) async {
  if (meetingId == '1') return MockData.sampleTranscript;
  return SupabaseService.instance.getTranscript(meetingId);
});
