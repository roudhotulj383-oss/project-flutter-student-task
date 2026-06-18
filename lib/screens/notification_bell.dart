import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/notification_services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION BELL — pengganti CircleAvatar(Icons.notifications_none) yang
// statis di header DashboardPage. Cara pakai (lihat dashboard.dart):
//
//   NotificationBell(snapshot: snapshot.data!)
//
// Widget ini TIDAK membuka koneksi Firestore sendiri — dia memakai ulang
// QuerySnapshot yang sama yang sudah didengarkan oleh StreamBuilder di
// DashboardPage (collection 'tasks', filter field 'uid'), supaya tidak ada
// listener Firestore dobel.
//
// CATATAN PENTING:
// - File ini meng-import '../Services/notification_service.dart' (SINGULAR,
//   huruf S besar sesuai folder kamu). Pastikan TIDAK ada lagi file bernama
//   'notification_services.dart' (PLURAL) di folder Services — hapus file
//   itu kalau masih ada, supaya tidak ada dua service yang membingungkan.
// ═══════════════════════════════════════════════════════════════════════════

class NotificationBell extends StatefulWidget {
  final QuerySnapshot<Object?> snapshot;

  const NotificationBell({super.key, required this.snapshot});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  // NotificationService adalah singleton (factory constructor),
  // jadi panggilan ini selalu mengembalikan instance yang sama
  // dengan yang dipakai di SettingsScreen, dsb.
  final _notifService = NotificationService();
  bool _isFirstSnapshot = true;

  @override
  void initState() {
    super.initState();
    _checkForNewTasks(widget.snapshot);
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      _checkForNewTasks(widget.snapshot);
    }
  }

  // Snapshot pertama berisi SEMUA tugas yang sudah ada (Firestore
  // melaporkannya sebagai "added"), jadi dilewati supaya tidak memicu
  // notifikasi dadakan untuk tugas lama setiap kali Dashboard dibuka.
  void _checkForNewTasks(QuerySnapshot<Object?> snapshot) {
    if (_isFirstSnapshot) {
      _isFirstSnapshot = false;
      return;
    }
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>? ?? {};
        _notifService.showInstantNotification(
          title: 'Tugas Baru Ditambahkan',
          body: (data['title'] ?? 'Tugas').toString(),
        );
      }
    }
  }

  List<_TaskNotification> _buildNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = widget.snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? 'Tugas').toString();
          final deadline = DateTime.tryParse(data['date']?.toString() ?? '');
          if (deadline == null) return null;

          final deadlineDay =
              DateTime(deadline.year, deadline.month, deadline.day);
          final daysUntil = deadlineDay.difference(today).inDays;

          if (daysUntil < 0) {
            return _TaskNotification(
              icon: Icons.error_rounded,
              color: const Color(0xFFFF4757),
              title: 'Lewat deadline',
              subtitle: title,
              sortKey: deadline,
            );
          }
          if (daysUntil <= 1) {
            return _TaskNotification(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFFB347),
              title: daysUntil == 0 ? 'Deadline hari ini' : 'Deadline besok',
              subtitle: title,
              sortKey: deadline,
            );
          }
          return null;
        })
        .whereType<_TaskNotification>()
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return items;
  }

  void _openPanel(List<_TaskNotification> notifications) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NotificationPanel(notifications: notifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _buildNotifications();
    final count = notifications.length;

    return GestureDetector(
      onTap: () => _openPanel(notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(
              count > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: Colors.blue,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskNotification {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime sortKey;

  _TaskNotification({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.sortKey,
  });
}

class _NotificationPanel extends StatelessWidget {
  final List<_TaskNotification> notifications;
  const _NotificationPanel({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notifikasi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada notifikasi saat ini',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: n.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(n.icon, color: n.color, size: 20),
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      n.subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}