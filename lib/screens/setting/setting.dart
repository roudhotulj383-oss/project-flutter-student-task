import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme_notif.dart';
import '../../services/notification_services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
//════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Singleton service
  final _notifService = NotificationService();

  // ── Firebase ──
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoadingProfile = true;

  // ── Notification Settings ──
  bool _notificationsEnabled = true;
  bool _taskReminderEnabled  = true;
  bool _deadlineAlertEnabled = true;
  bool _dailySummaryEnabled  = false;

  // ── Appearance Settings ──
  String _selectedLanguage   = 'Indonesia';
  String _selectedThemeColor = 'Biru';

  // ── Task Settings ──
  String _defaultPriority      = 'Sedang';
  bool   _autoArchiveCompleted = false;
  int    _reminderMinutes      = 30;

  // ── Profile ──
  // Dikosongkan dulu, akan diisi dari Firestore sesuai user yang login
  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nimController   = TextEditingController();

  final List<String> _languages      = ['Indonesia', 'English'];
  final List<String> _themeColors    = ['Biru', 'Hijau', 'Ungu', 'Oranye'];
  final List<String> _priorities     = ['Rendah', 'Sedang', 'Tinggi'];
  final List<int>    _reminderOptions = [5, 10, 15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _notifService.init(); // inisialisasi saat layar dibuka
    _loadUserProfile();   // ambil data profil sesuai user yang login
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    super.dispose();
  }


  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;

    // Jika tidak ada user yang login, isi email dari Auth saja (fallback)
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    
    _emailController.text = user.email ?? '';

    try {
      // Asumsi: collection 'users', document ID = uid user
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['nama'] ?? user.displayName ?? '';
        _nimController.text  = data['nim'] ?? '';
        // Email tetap pakai punya Auth, tapi fallback ke Firestore jika perlu
        if (_emailController.text.isEmpty) {
          _emailController.text = data['email'] ?? '';
        }
      } else {
        // Dokumen belum ada, pakai data dari Auth saja
        _nameController.text = user.displayName ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat data profil: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }


  Future<void> _saveUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'nama': _nameController.text.trim(),
        'nim': _nimController.text.trim(),
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Profil berhasil diperbarui', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menyimpan profil: $e', isSuccess: false);
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Catatan: SettingsScreen sekarang TIDAK punya Scaffold/AppBar sendiri.
    // Dipakai sebagai salah satu tab di dalam Scaffold milik DashboardPage
    // (lewat IndexedStack), jadi tombol back & AppBar terpisah tidak relevan
    // lagi — kalau ada "tidak ada yang bisa di-pop" itu sumbernya dari sini.
    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FF),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Pengaturan',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),

          // ── PROFIL ────────────────────────────────────────────────────
          _buildSectionHeader('Profil Mahasiswa', Icons.person_rounded),
          _buildProfileCard(),

          const SizedBox(height: 8),

          // ── NOTIFIKASI ────────────────────────────────────────────────
          _buildSectionHeader('Notifikasi', Icons.notifications_rounded),
          _buildCard(
            children: [
              // 1. Master toggle
              _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFF4A6CF7),
                title: 'Aktifkan Notifikasi',
                subtitle: 'Terima semua notifikasi tugas',
                value: _notificationsEnabled,
                onChanged: (val) async {
                  setState(() => _notificationsEnabled = val);
                  if (!val) {
                    await _notifService.cancelAll();
                    _showSnackBar('Semua notifikasi dimatikan',
                        isSuccess: false);
                  } else {
                    _showSnackBar('Notifikasi diaktifkan', isSuccess: true);
                  }
                },
              ),

              _buildDivider(),

              // 2. Pengingat Tugas
              _buildSwitchTile(
                icon: Icons.alarm_rounded,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Pengingat Tugas',
                subtitle: 'Notifikasi sebelum deadline',
                value: _taskReminderEnabled,
                onChanged: _notificationsEnabled
                    ? (val) async {
                        setState(() => _taskReminderEnabled = val);
                        if (val) {
                          // Jadwalkan pengingat contoh 2 jam dari sekarang
                          await _notifService.scheduleTaskReminder(
                            taskTitle: 'Tugas Aktif',
                            deadline: DateTime.now()
                                .add(const Duration(hours: 2)),
                            minutesBefore: _reminderMinutes,
                          );
                          _showSnackBar(
                              'Pengingat tugas diaktifkan',
                              isSuccess: true);
                        } else {
                          await _notifService.cancelTaskReminder();
                          _showSnackBar(
                              'Pengingat tugas dimatikan',
                              isSuccess: false);
                        }
                      }
                    : null,
              ),

              // Sub-opsi: pilih waktu pengingat
              if (_taskReminderEnabled && _notificationsEnabled) ...[
                _buildDivider(),
                _buildDropdownTile(
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFFFFB347),
                  title: 'Ingatkan Sebelum',
                  value: _reminderMinutes < 60
                      ? '$_reminderMinutes menit'
                      : '${_reminderMinutes ~/ 60} jam',
                  onTap: () => _showReminderPicker(),
                ),
              ],

              _buildDivider(),

              // 3. Peringatan Deadline
              _buildSwitchTile(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFF4757),
                title: 'Peringatan Deadline',
                subtitle: 'Alert saat mendekati batas waktu',
                value: _deadlineAlertEnabled,
                onChanged: _notificationsEnabled
                    ? (val) async {
                        setState(() => _deadlineAlertEnabled = val);
                        if (val) {
                          await _notifService.scheduleDeadlineAlert(
                            taskTitle: 'Tugas Aktif',
                            deadline: DateTime.now()
                                .add(const Duration(hours: 3)),
                          );
                          _showSnackBar(
                              'Peringatan deadline diaktifkan',
                              isSuccess: true);
                        } else {
                          await _notifService.cancelDeadlineAlert();
                          _showSnackBar(
                              'Peringatan deadline dimatikan',
                              isSuccess: false);
                        }
                      }
                    : null,
              ),

              _buildDivider(),

              // 4. Ringkasan Harian
              _buildSwitchTile(
                icon: Icons.summarize_rounded,
                iconColor: const Color(0xFF2ED573),
                title: 'Ringkasan Harian',
                subtitle: 'Laporan tugas setiap pagi pukul 07:00',
                value: _dailySummaryEnabled,
                onChanged: _notificationsEnabled
                    ? (val) async {
                        setState(() => _dailySummaryEnabled = val);
                        if (val) {
                          await _notifService.scheduleDailySummary(
                              taskCount: 5); // ganti dengan jumlah task nyata
                          _showSnackBar(
                              'Ringkasan harian dijadwalkan pukul 07:00',
                              isSuccess: true);
                        } else {
                          await _notifService.cancelDailySummary();
                          _showSnackBar(
                              'Ringkasan harian dimatikan',
                              isSuccess: false);
                        }
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── TAMPILAN ──────────────────────────────────────────────────
          _buildSectionHeader('Tampilan', Icons.palette_rounded),
          _buildCard(
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeNotifier.themeMode,
                builder: (context, mode, _) {
                  return _buildSwitchTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF5352ED),
                    title: 'Mode Gelap',
                    subtitle: 'Aktifkan tema gelap',
                    value: mode == ThemeMode.dark,
                    onChanged: (val) => ThemeNotifier.setDarkMode(val),
                  );
                },
              ),
              _buildDivider(),
              _buildDropdownTile(
                icon: Icons.color_lens_rounded,
                iconColor: const Color(0xFFFF6348),
                title: 'Warna Tema',
                value: _selectedThemeColor,
                onTap: () => _showPickerDialog(
                  title: 'Pilih Warna Tema',
                  options: _themeColors,
                  selected: _selectedThemeColor,
                  onSelected: (val) =>
                      setState(() => _selectedThemeColor = val),
                ),
              ),
              _buildDivider(),
              _buildDropdownTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF1E90FF),
                title: 'Bahasa',
                value: _selectedLanguage,
                onTap: () => _showPickerDialog(
                  title: 'Pilih Bahasa',
                  options: _languages,
                  selected: _selectedLanguage,
                  onSelected: (val) =>
                      setState(() => _selectedLanguage = val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── AKUN ──────────────────────────────────────────────────────
          _buildSectionHeader('Akun', Icons.manage_accounts_rounded),
          _buildCard(
            children: [
              _buildActionTile(
                icon: Icons.lock_reset_rounded,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Ubah Kata Sandi',
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFFF4757),
                title: 'Hapus Semua Tugas',
                titleColor: const Color(0xFFFF4757),
                onTap: () => _showDeleteConfirmation(),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFFF4757),
                title: 'Keluar',
                titleColor: const Color(0xFFFF4757),
                onTap: () => _showLogoutConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Student Task App © 2026',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGETS PEMBANTU
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A6CF7)),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A6CF7),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileCard() {
    // Tampilkan shimmer/loading singkat selagi data diambil dari Firestore
    if (_isLoadingProfile) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A6CF7), Color(0xFF6A85F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final displayName =
        _nameController.text.isNotEmpty ? _nameController.text : 'Pengguna';
    final displayNim =
        _nimController.text.isNotEmpty ? _nimController.text : '-';
    final displayEmail =
        _emailController.text.isNotEmpty ? _emailController.text : '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF6A85F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6CF7).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayNim,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      displayEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Edit Profil',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Opacity(
      opacity: onChanged == null ? 0.45 : 1.0,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: _iconBox(icon, iconColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
              )
            : null,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4A6CF7),
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(icon, iconColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            color: titleColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(
        height: 1,
        indent: 64,
        endIndent: 16,
        color: Colors.grey.shade100,
      );

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      );

  

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF4A6CF7)),
            SizedBox(width: 8),
            Text('Edit Profil',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nimController,
              label: 'NIM',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              // Email dikunci karena bersumber dari akun Firebase Auth.
              // Ubah email login lewat menu khusus, bukan dari sini.
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveUserProfile();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showPickerDialog({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
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
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt),
                leading: Radio<String>(
                  value: opt,
                  groupValue: selected,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (val) {
                    if (val != null) {
                      onSelected(val);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder agar radio update di dalam bottom sheet
        builder: (ctx, setSheetState) => Padding(
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
                'Ingatkan Sebelum Deadline',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._reminderOptions.map(
                (min) => ListTile(
                  title: Text(min < 60
                      ? '$min menit sebelumnya'
                      : '${min ~/ 60} jam sebelumnya'),
                  leading: Radio<int>(
                    value: min,
                    groupValue: _reminderMinutes,
                    activeColor: const Color(0xFF4A6CF7),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _reminderMinutes = val);
                        setSheetState(() {});
                        Navigator.pop(context);
                      }
                    },
                  ),
                  onTap: () {
                    setState(() => _reminderMinutes = min);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFFF4757)),
              SizedBox(width: 8),
              Text('Hapus Semua Tugas'),
            ],
          ),
          content: const Text(
            'Semua data tugas akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed:
                  isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      await _deleteAllTasks();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _deleteAllTasks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .get();

      final docs = tasksSnapshot.docs;
      if (docs.isEmpty) {
        if (mounted) {
          _showSnackBar('Tidak ada tugas untuk dihapus', isSuccess: false);
        }
        return;
      }

      // Batalkan reminder terjadwal milik tiap task SEBELUM dihapus,
      // supaya tidak ada notifikasi nyasar untuk task yang sudah tidak ada.
      for (final doc in docs) {
        await NotificationService().cancelNotificationByDocId(doc.id);
      }

      // Firestore membatasi 500 operasi per batch, jadi dipecah per 500 dokumen
      const chunkSize = 500;
      for (var i = 0; i < docs.length; i += chunkSize) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(chunkSize)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (mounted) {
        _showSnackBar('${docs.length} tugas berhasil dihapus',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menghapus tugas: $e', isSuccess: false);
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF4757)),
            SizedBox(width: 8),
            Text('Keluar'),
          ],
        ),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // tutup dialog konfirmasi dulu
              try {
                await _auth.signOut();
                if (!mounted) return;
                // CATATAN: ganti '/login' sesuai nama named route halaman
                // login di app kamu. Kalau belum pakai named routes,
                // pakai MaterialPageRoute seperti contoh di bawah:
                //
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (_) => const LoginScreen()),
                //   (route) => false,
                // );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Gagal keluar: $e', isSuccess: false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> handleChangePassword() async {
            if (!formKey.currentState!.validate()) return;

            setDialogState(() {
              isLoading = true;
              errorMessage = null;
            });

            final user = _auth.currentUser;
            if (user == null || user.email == null) {
              setDialogState(() {
                isLoading = false;
                errorMessage =
                    'Akun ini tidak menggunakan login email & password.';
              });
              return;
            }

            try {
              // Firebase wajib re-autentikasi sebelum boleh ganti password
              final credential = EmailAuthProvider.credential(
                email: user.email!,
                password: currentPasswordController.text,
              );
              await user.reauthenticateWithCredential(credential);
              await user.updatePassword(newPasswordController.text);

              if (mounted) {
                Navigator.pop(dialogContext);
                _showSnackBar('Kata sandi berhasil diubah', isSuccess: true);
              }
            } on FirebaseAuthException catch (e) {
              String message;
              switch (e.code) {
                case 'wrong-password':
                case 'invalid-credential':
                  message = 'Kata sandi saat ini salah';
                  break;
                case 'weak-password':
                  message = 'Kata sandi baru terlalu lemah (minimal 6 karakter)';
                  break;
                case 'requires-recent-login':
                  message =
                      'Sesi login terlalu lama, silakan keluar lalu masuk lagi';
                  break;
                case 'too-many-requests':
                  message = 'Terlalu banyak percobaan, coba lagi nanti';
                  break;
                default:
                  message = 'Gagal mengubah kata sandi: ${e.message}';
              }
              setDialogState(() {
                isLoading = false;
                errorMessage = message;
              });
            } catch (e) {
              setDialogState(() {
                isLoading = false;
                errorMessage = 'Terjadi kesalahan: $e';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF4A6CF7)),
                SizedBox(width: 8),
                Text('Ubah Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Saat Ini',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF4A6CF7)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: Color(0xFF4A6CF7)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (val.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: Color(0xFF4A6CF7)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (val != newPasswordController.text) {
                          return 'Kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                              color: Color(0xFFFF4757), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child:
                    const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor:
            isSuccess ? const Color(0xFF2ED573) : const Color(0xFFFF4757),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A6CF7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4A6CF7), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}