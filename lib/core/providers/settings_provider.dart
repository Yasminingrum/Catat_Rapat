import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Pilihan Pengaturan ────────────────────────────────────────

enum AppLanguage { indonesia, english }

extension AppLanguageX on AppLanguage {
  String get label => switch (this) {
    AppLanguage.indonesia => 'Bahasa Indonesia',
    AppLanguage.english => 'English',
  };
}

enum NotulaLanguage { indonesia, english }

extension NotulaLanguageX on NotulaLanguage {
  String get label => switch (this) {
    NotulaLanguage.indonesia => 'Bahasa Indonesia',
    NotulaLanguage.english => 'English',
  };
}

enum RecordingQuality { standard, high, veryHigh }

enum RetentionPeriod { days30, days90, year1, forever }

// ── State & Notifier ──────────────────────────────────────────

class SettingsState {
  const SettingsState({
    this.language = AppLanguage.indonesia,
    this.notulaLanguage = NotulaLanguage.indonesia,
    this.recordingQuality = RecordingQuality.standard,
    this.retention = RetentionPeriod.days90,
    this.notifActionReminder = true,
    this.notifSummaryReady = true,
  });

  final AppLanguage language;
  final NotulaLanguage notulaLanguage;
  final RecordingQuality recordingQuality;
  final RetentionPeriod retention;
  final bool notifActionReminder;
  final bool notifSummaryReady;

  SettingsState copyWith({
    AppLanguage? language,
    NotulaLanguage? notulaLanguage,
    RecordingQuality? recordingQuality,
    RetentionPeriod? retention,
    bool? notifActionReminder,
    bool? notifSummaryReady,
  }) => SettingsState(
    language: language ?? this.language,
    notulaLanguage: notulaLanguage ?? this.notulaLanguage,
    recordingQuality: recordingQuality ?? this.recordingQuality,
    retention: retention ?? this.retention,
    notifActionReminder: notifActionReminder ?? this.notifActionReminder,
    notifSummaryReady: notifSummaryReady ?? this.notifSummaryReady,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _kLanguage = 'settings_language';
  static const _kNotulaLanguage = 'settings_notula_language';
  static const _kRecordingQuality = 'settings_recording_quality';
  static const _kRetention = 'settings_retention';
  static const _kNotifActionReminder = 'settings_notif_action_reminder';
  static const _kNotifSummaryReady = 'settings_notif_summary_ready';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      language: AppLanguage.values[prefs.getInt(_kLanguage) ?? 0],
      notulaLanguage: NotulaLanguage.values[prefs.getInt(_kNotulaLanguage) ?? 0],
      recordingQuality: RecordingQuality.values[prefs.getInt(_kRecordingQuality) ?? 0],
      retention: RetentionPeriod.values[prefs.getInt(_kRetention) ?? 1],
      notifActionReminder: prefs.getBool(_kNotifActionReminder) ?? true,
      notifSummaryReady: prefs.getBool(_kNotifSummaryReady) ?? true,
    );
  }

  Future<void> setLanguage(AppLanguage value) async {
    state = state.copyWith(language: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLanguage, value.index);
  }

  Future<void> setNotulaLanguage(NotulaLanguage value) async {
    state = state.copyWith(notulaLanguage: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotulaLanguage, value.index);
  }

  Future<void> setRecordingQuality(RecordingQuality value) async {
    state = state.copyWith(recordingQuality: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRecordingQuality, value.index);
  }

  Future<void> setRetention(RetentionPeriod value) async {
    state = state.copyWith(retention: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRetention, value.index);
  }

  Future<void> setNotifActionReminder(bool value) async {
    state = state.copyWith(notifActionReminder: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifActionReminder, value);
  }

  Future<void> setNotifSummaryReady(bool value) async {
    state = state.copyWith(notifSummaryReady: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifSummaryReady, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
    (ref) => SettingsNotifier());
