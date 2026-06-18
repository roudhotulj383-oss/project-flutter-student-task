import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ID tetap untuk tiap jenis notifikasi
  static const int _taskReminderId = 1001;
  static const int _deadlineAlertId = 1002;
  static const int _dailySummaryId = 1003;

  // ─── HELPER: ID NOTIFIKASI DARI DOCUMENT ID FIRESTORE ────────────────────
  // flutter_local_notifications butuh id berupa int 32-bit, sementara
  // document ID Firestore berupa String acak (contoh: "aB3xZ9..."). 
  // hashCode lalu di-mask ke 31 bit positif supaya selalu valid sebagai
  // notification id dan tidak collision dengan id tetap di atas (1001-1003).
  static int idFromDocId(String docId) {
    return docId.hashCode & 0x7FFFFFFF;
  }

  // ─── INIT ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android: pakai sound default sistem
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Minta izin notifikasi (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Minta izin exact alarm (Android 12+). Tanpa ini, zonedSchedule
    // dengan exactAllowWhileIdle bisa gagal dijadwalkan TANPA error
    // yang terlihat — penyebab paling umum notifikasi tidak muncul
    // sama sekali di Android versi baru.
    await androidPlugin?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  // ─── CEK STATUS IZIN (debugging) ───────────────────────────────────────────
  Future<bool?> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return androidPlugin?.areNotificationsEnabled();
  }

  // ─── DETAIL CHANNEL (dengan BUNYI) ───────────────────────────────────────
  AndroidNotificationDetails _androidDetail({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      playSound: true,                          // ← BUNYI aktif
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
      // Catatan: RawResourceAndroidNotificationSound('notification')
      // butuh file res/raw/notification.mp3 (atau .wav/.ogg) ada di
      // project Android. Kalau file itu belum ditambahkan, channel
      // akan gagal dibuat / suara tidak keluar tanpa error yang jelas.
      // Sementara pakai sound default sistem dulu sampai file custom
      // sudah dipastikan ada — lihat catatan di bawah skill ini.
    );
  }

  // ─── 1. PENGINGAT TUGAS (terjadwal X menit sebelum deadline) ─────────────
  Future<void> scheduleTaskReminder({
    required String taskTitle,
    required DateTime deadline,
    required int minutesBefore,
  }) async {
    await init();
    final scheduledTime = deadline.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return; // sudah lewat

    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'task_reminder',
        channelName: 'Pengingat Tugas',
        channelDesc: 'Notifikasi pengingat sebelum deadline tugas',
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );

    await _plugin.zonedSchedule(
      _taskReminderId,
      '⏰ Pengingat Tugas',
      '$taskTitle — $minutesBefore menit lagi!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── 2. PERINGATAN DEADLINE (notif langsung saat deadline tiba) ───────────
  Future<void> scheduleDeadlineAlert({
    required String taskTitle,
    required DateTime deadline,
  }) async {
    await init();
    if (deadline.isBefore(DateTime.now())) return;

    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'deadline_alert',
        channelName: 'Peringatan Deadline',
        channelDesc: 'Alert saat batas waktu tugas tiba',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );

    await _plugin.zonedSchedule(
      _deadlineAlertId,
      '🚨 Deadline Tiba!',
      'Waktu untuk "$taskTitle" telah habis!',
      tz.TZDateTime.from(deadline, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── 3. RINGKASAN HARIAN (setiap pagi jam 07:00) ─────────────────────────
  Future<void> scheduleDailySummary({required int taskCount}) async {
    await init();

    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'daily_summary',
        channelName: 'Ringkasan Harian',
        channelDesc: 'Laporan tugas setiap pagi',
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );

    // Jadwalkan jam 07:00 setiap hari
    await _plugin.zonedSchedule(
      _dailySummaryId,
      '📋 Ringkasan Tugas Hari Ini',
      'Kamu punya $taskCount tugas yang perlu diselesaikan hari ini.',
      _nextInstanceOfTime(7, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ← ulangi setiap hari
    );
  }

  // ─── TES LANGSUNG (notifikasi muncul instan, untuk debugging) ────────────
  // Panggil ini untuk memastikan suara & tampilan notifikasi bekerja,
  // tanpa perlu menunggu jadwal. Kalau ini saja tidak muncul/berbunyi,
  // masalahnya pasti di izin OS, bukan di logic scheduling.
  Future<void> showTestNotification() async {
    await init();
    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'test_channel',
        channelName: 'Tes Notifikasi',
        channelDesc: 'Channel untuk menguji notifikasi',
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );
    await _plugin.show(
      9999,
      '🔔 Tes Notifikasi',
      'Kalau ini muncul dan berbunyi, sistem notifikasi sudah benar.',
      details,
    );
  }

  // ─── 4. NOTIFIKASI INSTAN (langsung tampil, bukan terjadwal) ─────────────
  // Dipakai saat ada tugas baru terdeteksi dari Firestore (real-time),
  // dipanggil dari NotificationBell.
  int _instantNotifCounter = 2000; // di luar rentang ID 1001-1003 di atas

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await init();
    _instantNotifCounter++;

    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'instant_notification',
        channelName: 'Notifikasi Instan',
        channelDesc: 'Notifikasi langsung, contoh saat tugas baru dibuat',
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );

    await _plugin.show(_instantNotifCounter, title, body, details);
  }

  // ─── NOTIFIKASI TERJADWAL DENGAN ID CUSTOM (generik) ─────────────────────
  // Dipakai saat satu task butuh satu notifikasi unik miliknya sendiri
  // (misalnya reminder per-task di AddTaskPage), beda dengan tiga ID
  // tetap (_taskReminderId dkk) yang cuma untuk satu notifikasi "global".
  // Kalau scheduledDate sudah lewat, dilewati saja (tidak schedule).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    if (scheduledDate.isBefore(DateTime.now())) return;

    final details = NotificationDetails(
      android: _androidDetail(
        channelId: 'task_specific_reminder',
        channelName: 'Reminder Tugas',
        channelDesc: 'Pengingat untuk tugas tertentu yang kamu set',
      ),
      iOS: const DarwinNotificationDetails(sound: 'default'),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Batalkan notifikasi reminder per-task berdasarkan document ID-nya.
  Future<void> cancelNotificationByDocId(String docId) async {
    await _plugin.cancel(idFromDocId(docId));
  }

  // ─── CANCEL ───────────────────────────────────────────────────────────────
  Future<void> cancelTaskReminder() async =>
      _plugin.cancel(_taskReminderId);

  Future<void> cancelDeadlineAlert() async =>
      _plugin.cancel(_deadlineAlertId);

  Future<void> cancelDailySummary() async =>
      _plugin.cancel(_dailySummaryId);

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── HELPER ───────────────────────────────────────────────────────────────
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}