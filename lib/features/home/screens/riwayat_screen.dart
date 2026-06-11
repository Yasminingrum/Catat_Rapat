import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/meeting_card.dart';

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});
  @override ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _tab = 0;

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(meetingListProvider);
    return Scaffold(backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(24,16,24,0), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Riwayat Rapat', style: AppTextStyles.displayLg()),
          const SizedBox(height: 16),
          Container(height: 44, decoration: BoxDecoration(color: AppColors.background,
              borderRadius: AppRadius.md, border: Border.all(color: AppColors.borderMedium)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.only(left:12,right:8),
                  child: Icon(Icons.search_rounded, size:18, color: AppColors.textTertiary)),
              Expanded(child: TextField(controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodyMd(),
                decoration: InputDecoration(hintText: 'Cari rapat...',
                    hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                    border: InputBorder.none, contentPadding: EdgeInsets.zero))),
              if (_query.isNotEmpty) GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _query=''); },
                  child: const Padding(padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, size:16, color: AppColors.textTertiary))),
            ])),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: ['Semua','Minggu Ini','Bulan Ini'].asMap().entries.map((e) =>
              GestureDetector(onTap: () => setState(() => _tab = e.key),
                child: Container(margin: const EdgeInsets.only(right:8),
                    padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
                    decoration: BoxDecoration(
                        color: _tab == e.key ? AppColors.primaryLight : Colors.transparent,
                        borderRadius: AppRadius.full),
                    child: Text(e.value, style: AppTextStyles.bodyMd(
                        c: _tab == e.key ? AppColors.primary : AppColors.textTertiary,
                        w: _tab == e.key ? FontWeight.w600 : FontWeight.w400))))).toList())),
          const SizedBox(height: 12),
        ])),
        const Divider(height:1),
        Expanded(child: meetingsAsync.when(
          data: (meetings) {
            var filtered = _query.isEmpty ? meetings
                : meetings.where((m) => m.title.toLowerCase().contains(_query.toLowerCase())).toList();
            if (_tab != 0) {
              final now = DateTime.now();
              final startOfWeek = DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: now.weekday - 1));
              filtered = filtered.where((m) {
                final d = DateFormatter.parseDate(m.date);
                if (d == null) return false;
                return _tab == 1
                    ? !d.isBefore(startOfWeek) && !d.isAfter(now)
                    : d.year == now.year && d.month == now.month;
              }).toList();
            }
            if (filtered.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.search_off_rounded, size:40, color: AppColors.divider),
              const SizedBox(height:12),
              Text(_query.isEmpty ? 'Belum ada rapat' : 'Tidak ada hasil', style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            ]));
            }
            return RefreshIndicator(color: AppColors.primary,
              onRefresh: () => ref.read(meetingListProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24,16,24,96),
                itemCount: filtered.length,
                separatorBuilder: (_,__) => const SizedBox(height:12),
                itemBuilder: (_, i) => MeetingCard(meeting: filtered[i],
                    onTap: () => context.push('/rapat/${filtered[i].id}'))));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text('Error: $e')),
        )),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
