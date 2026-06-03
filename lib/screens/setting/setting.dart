import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification Settings
  bool _notificationsEnabled = true;
  bool _taskReminderEnabled = true;
  bool _deadlineAlertEnabled = true;
  bool _dailySummaryEnabled = false;

  // Appearance Settings
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Indonesia';
  String _selectedThemeColor = 'Biru';

  // Task Settings
  String _defaultPriority = 'Sedang';
  bool _autoArchiveCompleted = false;
  int _reminderMinutes = 30;

  // Profile
  final TextEditingController _nameController =
      TextEditingController(text: 'Roudhotul Jannah');
  final TextEditingController _emailController =
      TextEditingController(text: 'roudhotulj383@gmail.com');
  final TextEditingController _nimController =
      TextEditingController(text: '202369040027');

  final List<String> _languages = ['Indonesia', 'English'];
  final List<String> _themeColors = ['Biru', 'Hijau', 'Ungu', 'Oranye'];
  final List<String> _priorities = ['Rendah', 'Sedang', 'Tinggi'];
  final List<int> _reminderOptions = [5, 10, 15, 30, 60, 120];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── PROFIL ──────────────────────────────────────────
          _buildSectionHeader('Profil Mahasiswa', Icons.person_rounded),
          _buildProfileCard(),

          const SizedBox(height: 8),

          // ── NOTIFIKASI ───────────────────────────────────────
          _buildSectionHeader('Notifikasi', Icons.notifications_rounded),
          _buildCard(
            children: [ 
              _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFF4A6CF7),
                title: 'Aktifkan Notifikasi',
                subtitle: 'Terima semua notifikasi tugas',
                value: _notificationsEnabled,
                onChanged: (val) =>
                    setState(() => _notificationsEnabled = val),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.alarm_rounded,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Pengingat Tugas',
                subtitle: 'Notifikasi sebelum deadline',
                value: _taskReminderEnabled,
                onChanged: _notificationsEnabled
                    ? (val) => setState(() => _taskReminderEnabled = val)
                    : null,
              ),
              if (_taskReminderEnabled && _notificationsEnabled) ...[
                _buildDivider(),
                _buildDropdownTile(
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFFFFB347),
                  title: 'Ingatkan Sebelum',
                  value: '$_reminderMinutes menit',
                  onTap: () => _showReminderPicker(),
                ),
              ],
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFF4757),
                title: 'Peringatan Deadline',
                subtitle: 'Alert saat mendekati batas waktu',
                value: _deadlineAlertEnabled,
                onChanged: _notificationsEnabled
                    ? (val) => setState(() => _deadlineAlertEnabled = val)
                    : null,
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.summarize_rounded,
                iconColor: const Color(0xFF2ED573),
                title: 'Ringkasan Harian',
                subtitle: 'Laporan tugas setiap pagi',
                value: _dailySummaryEnabled,
                onChanged: _notificationsEnabled
                    ? (val) => setState(() => _dailySummaryEnabled = val)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── TAMPILAN ─────────────────────────────────────────
          _buildSectionHeader('Tampilan', Icons.palette_rounded),
          _buildCard(
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF5352ED),
                title: 'Mode Gelap',
                subtitle: 'Aktifkan tema gelap',
                value: _darkModeEnabled,
                onChanged: (val) => setState(() => _darkModeEnabled = val),
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

          // ── PENGATURAN TUGAS ─────────────────────────────────
          _buildSectionHeader('Pengaturan Tugas', Icons.task_alt_rounded),
          _buildCard(
            children: [
              _buildDropdownTile(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Prioritas Default',
                value: _defaultPriority,
                onTap: () => _showPickerDialog(
                  title: 'Pilih Prioritas Default',
                  options: _priorities,
                  selected: _defaultPriority,
                  onSelected: (val) =>
                      setState(() => _defaultPriority = val),
                ),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.archive_rounded,
                iconColor: const Color(0xFF747D8C),
                title: 'Arsip Otomatis',
                subtitle: 'Arsipkan tugas selesai secara otomatis',
                value: _autoArchiveCompleted,
                onChanged: (val) =>
                    setState(() => _autoArchiveCompleted = val),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── TENTANG ──────────────────────────────────────────
          _buildSectionHeader('Tentang Aplikasi', Icons.info_rounded),
          _buildCard(
            children: [
              _buildInfoTile(
                icon: Icons.apps_rounded,
                iconColor: const Color(0xFF4A6CF7),
                title: 'Versi Aplikasi',
                trailing: '1.0.0',
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.school_rounded,
                iconColor: const Color(0xFF2ED573),
                title: 'Developer',
                trailing: 'Tim Proyek',
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF5352ED),
                title: 'Kebijakan Privasi',
                onTap: () => _showComingSoon('Kebijakan Privasi'),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFFFFB347),
                title: 'Bantuan & Dukungan',
                onTap: () => _showComingSoon('Bantuan & Dukungan'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── AKUN ─────────────────────────────────────────────
          _buildSectionHeader('Akun', Icons.manage_accounts_rounded),
          _buildCard(
            children: [
              _buildActionTile(
                icon: Icons.lock_reset_rounded,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Ubah Kata Sandi',
                onTap: () => _showComingSoon('Ubah Kata Sandi'),
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
              'Student Task App © 2024',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── WIDGETS PEMBANTU ─────────────────────────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
                      _nameController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nimController.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _emailController.text,
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
                  borderRadius: BorderRadius.circular(10),
                ),
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
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
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(icon, iconColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      trailing: Text(
        trailing,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
      ),
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
          color: titleColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ─── DIALOG & PICKER ─────────────────────────────────────────────────────

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              _showSnackBar('Profil berhasil diperbarui', isSuccess: true);
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
            Text(
              title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
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
            const Text(
              'Ingatkan Sebelum Deadline',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._reminderOptions.map(
              (min) => ListTile(
                title: Text(
                  min < 60
                      ? '$min menit sebelumnya'
                      : '${min ~/ 60} jam sebelumnya',
                ),
                leading: Radio<int>(
                  value: min,
                  groupValue: _reminderMinutes,
                  activeColor: const Color(0xFF4A6CF7),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _reminderMinutes = val);
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
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Semua tugas berhasil dihapus',
                  isSuccess: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Tambahkan logika logout (clear session, navigate to login)
              _showSnackBar('Berhasil keluar', isSuccess: true);
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(message),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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