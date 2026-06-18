import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/pending_recording_service.dart';
import '../../../core/widgets/app_bottom_nav.dart';

enum _RiwayatFilter { semua, berbintang, selesai, proses }

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});
  @override ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _RiwayatFilter _filter = _RiwayatFilter.semua;
  List<PendingRecording> _pendingRecordings = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final list = await PendingRecordingService.instance.getAll();
    if (mounted) setState(() => _pendingRecordings = list);
  }

  Future<void> _deletePending(PendingRecording rec) async {
    await PendingRecordingService.instance.remove(rec.filePath);
    try { await File(rec.filePath).delete(); } catch (_) {}
    await _loadPending();
  }

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _confirmDelete(Meeting meeting) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text(s.riwayatDeleteTitle, style: AppTextStyles.displaySm()),
        content: Text(s.riwayatDeleteContent(meeting.title),
            style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.commonCancel, style: AppTextStyles.bodyMd(c: AppColors.textSecondary, w: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.commonDelete, style: AppTextStyles.bodyMd(c: AppColors.error, w: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(meetingListProvider.notifier).deleteMeeting(meeting.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final s = ref.watch(appStringsProvider);
    return Scaffold(backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(24,16,24,16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.riwayatTitle, style: AppTextStyles.displayLg()),
          const SizedBox(height: 16),
          Container(height: 44, decoration: BoxDecoration(color: AppColors.background,
              borderRadius: AppRadius.md, border: Border.all(color: AppColors.borderMedium)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.only(left:12,right:8),
                  child: Icon(Icons.search_rounded, size:18, color: AppColors.textTertiary)),
              Expanded(child: TextField(controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodyMd(),
                decoration: InputDecoration(hintText: s.riwayatSearchHint,
                    hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                    border: InputBorder.none, contentPadding: EdgeInsets.zero))),
              if (_query.isNotEmpty) GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _query=''); },
                  child: const Padding(padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, size:16, color: AppColors.textTertiary))),
            ])),
          const SizedBox(height: 12),
          meetingsAsync.when(
            data: (meetings) {
              final starredCount = meetings.where((m) => m.isStarred).length;
              return SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: s.riwayatFilterAll, active: _filter == _RiwayatFilter.semua,
                      onTap: () => setState(() => _filter = _RiwayatFilter.semua)),
                  const SizedBox(width: 8),
                  _FilterChip(label: s.riwayatFilterStarred(starredCount), active: _filter == _RiwayatFilter.berbintang,
                      onTap: () => setState(() => _filter = _RiwayatFilter.berbintang)),
                  const SizedBox(width: 8),
                  _FilterChip(label: s.riwayatFilterDone, active: _filter == _RiwayatFilter.selesai,
                      onTap: () => setState(() => _filter = _RiwayatFilter.selesai)),
                  const SizedBox(width: 8),
                  _FilterChip(label: s.riwayatFilterInProgress, active: _filter == _RiwayatFilter.proses,
                      onTap: () => setState(() => _filter = _RiwayatFilter.proses)),
                ]));
            },
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ])),
        const Divider(height:1),
        Expanded(child: meetingsAsync.when(
          data: (meetings) {
            var filtered = _query.isEmpty ? meetings
                : meetings.where((m) => m.title.toLowerCase().contains(_query.toLowerCase())).toList();
            filtered = switch (_filter) {
              _RiwayatFilter.semua => filtered,
              _RiwayatFilter.berbintang => filtered.where((m) => m.isStarred).toList(),
              _RiwayatFilter.selesai => filtered.where((m) => m.status == MeetingStatus.final_).toList(),
              _RiwayatFilter.proses => filtered.where((m) => m.status == MeetingStatus.draft).toList(),
            };
            if (filtered.isEmpty && _pendingRecordings.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_query.isEmpty ? Icons.calendar_today_outlined : Icons.search_off_rounded,
                    size:40, color: AppColors.divider),
                const SizedBox(height:12),
                Text(_query.isEmpty ? s.riwayatEmptyTitle : s.riwayatEmptySearchTitle,
                    style: AppTextStyles.bodyMd(c: AppColors.textSecondary, w: FontWeight.w500)),
                if (_query.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(s.riwayatEmptySearchSubtitle, style: AppTextStyles.bodySm(c: AppColors.textTertiary)),
                ],
              ]));
            }
            final pendingCount = _pendingRecordings.length;
            final totalCount = pendingCount + (pendingCount > 0 ? 1 : 0) + filtered.length;
            return RefreshIndicator(color: AppColors.primary,
              onRefresh: () async {
                await ref.read(meetingListProvider.notifier).refresh();
                await _loadPending();
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24,16,24,96),
                itemCount: totalCount,
                separatorBuilder: (_,__) => const SizedBox(height:12),
                itemBuilder: (_, i) {
                  if (pendingCount > 0 && i < pendingCount) {
                    final rec = _pendingRecordings[i];
                    return _PendingRecordingCard(
                      s: s,
                      recording: rec,
                      showHeader: i == 0,
                      onProcess: () async {
                        await context.push('/processing', extra: {
                          'title': rec.title,
                          'agenda': rec.agenda,
                          'filePath': rec.filePath,
                          'durationSeconds': rec.durationSeconds,
                        });
                        _loadPending();
                      },
                      onDelete: () => _deletePending(rec),
                    );
                  }
                  if (pendingCount > 0 && i == pendingCount) {
                    return const SizedBox(height: 4);
                  }
                  final mi = i - pendingCount - (pendingCount > 0 ? 1 : 0);
                  final m = filtered[mi];
                  return _RiwayatMeetingCard(meeting: m, s: s,
                    onTap: () => context.push('/rapat/${m.id}'),
                    onToggleStar: () => ref.read(meetingListProvider.notifier).toggleStar(m.id),
                    onDelete: () => _confirmDelete(m),
                    onReprocess: () => context.push('/processing', extra: {
                      'title': m.title,
                      'existingMeetingId': m.id,
                      'existingAudioPath': m.audioPath,
                    }));
                }));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text('${s.commonError}: $e')),
        )),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.background,
            borderRadius: AppRadius.full),
        child: Text(label, style: AppTextStyles.bodyMd(
            c: active ? Colors.white : AppColors.textSecondary,
            w: active ? FontWeight.w600 : FontWeight.w400))));
}

class _RiwayatMeetingCard extends StatelessWidget {
  const _RiwayatMeetingCard({
    required this.meeting, required this.s, required this.onTap,
    required this.onToggleStar, required this.onDelete, required this.onReprocess,
  });
  final Meeting meeting;
  final AppStrings s;
  final VoidCallback onTap, onToggleStar, onDelete, onReprocess;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: onToggleStar,
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: meeting.isStarred ? AppColors.warningLight : Colors.transparent,
                  shape: BoxShape.circle),
              child: Icon(meeting.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: meeting.isStarred ? AppColors.warning : AppColors.textTertiary, size: 20))),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(meeting.title, style: AppTextStyles.displayXs(w: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textTertiary),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
              onSelected: (v) {
                if (v == 'star') {
                  onToggleStar();
                } else if (v == 'delete') {
                  onDelete();
                } else if (v == 'reprocess') {
                  onReprocess();
                }
              },
              itemBuilder: (_) => [
                if (meeting.isFailed)
                  PopupMenuItem(value: 'reprocess', child: Row(children: [
                    const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(s.riwayatReprocessMenuItem, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w600)),
                  ])),
                PopupMenuItem(value: 'star', child: Row(children: [
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(meeting.isStarred ? s.riwayatUnstar : s.riwayatStar, style: AppTextStyles.bodyMd()),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(s.riwayatDeleteMeeting, style: AppTextStyles.bodyMd(c: AppColors.error)),
                ])),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(meeting.duration, style: AppTextStyles.caption(c: AppColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(s.riwayatParticipants(meeting.participants.length), style: AppTextStyles.caption(c: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text(meeting.date, style: AppTextStyles.caption(c: AppColors.textTertiary)),
            const SizedBox(width: 8),
            _StatusBadge(meeting: meeting, s: s),
          ]),
        ])),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.meeting, required this.s});
  final Meeting meeting;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    if (meeting.isFailed) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
      label = s.riwayatStatusFailed;
    } else if (meeting.status == MeetingStatus.draft) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
      label = s.riwayatStatusInProgress;
    } else {
      bg = AppColors.successLight;
      fg = AppColors.success;
      label = s.riwayatStatusDone;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.full),
      child: Text(label, style: AppTextStyles.caption(c: fg, w: FontWeight.w600)),
    );
  }
}

class _PendingRecordingCard extends StatelessWidget {
  const _PendingRecordingCard({
    required this.s,
    required this.recording,
    required this.showHeader,
    required this.onProcess,
    required this.onDelete,
  });

  final AppStrings s;
  final PendingRecording recording;
  final bool showHeader;
  final VoidCallback onProcess;
  final VoidCallback onDelete;

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(children: [
            const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(s.riwayatPendingSectionTitle,
                style: AppTextStyles.bodySm(c: AppColors.warning, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
        ],
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recording.title,
                  style: AppTextStyles.displayXs(w: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(_formatDuration(recording.durationSeconds),
                    style: AppTextStyles.caption(c: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(DateFormat('d MMM yyyy').format(recording.createdAt),
                    style: AppTextStyles.caption(c: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onProcess,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.md,
                      ),
                      child: Center(child: Text(s.riwayatPendingProcess,
                          style: AppTextStyles.bodySm(c: Colors.white, w: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppRadius.md,
                    ),
                    child: Text(s.riwayatPendingDelete,
                        style: AppTextStyles.bodySm(c: AppColors.error, w: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
