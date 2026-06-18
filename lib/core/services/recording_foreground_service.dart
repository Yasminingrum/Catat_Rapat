import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void initRecordingForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'recording_channel',
      channelName: 'Rekaman Rapat',
      channelDescription: 'Rekaman rapat sedang berlangsung',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}

Future<void> startRecordingForegroundService() async {
  initRecordingForegroundTask();
  await FlutterForegroundTask.startService(
    serviceId: 256,
    notificationTitle: 'CatatRapat',
    notificationText: 'Rekaman rapat sedang berlangsung...',
    callback: _startCallback,
  );
}

Future<void> stopRecordingForegroundService() async {
  await FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
