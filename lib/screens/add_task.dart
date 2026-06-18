import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'category.dart';
import 'reminder.dart';
import '../services/notification_services.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDeadline;
  DateTime? _selectedReminder;
  String? _selectedCategory;
  bool _isSaving = false;

  // Subtask controllers dikelola dalam satu list agar mudah di-dispose
  List<TextEditingController> _subtaskControllers = [
    TextEditingController(),
  ];
  List<bool> _subtaskDone = [false];

  // ─── DISPOSE semua controller ──────────────────────────────────
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── TAMBAH SUBTASK ────────────────────────────────────────────
  void _addSubtask() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
      _subtaskDone.add(false);
    });
  }

  // ─── HAPUS SUBTASK ─────────────────────────────────────────────
  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtaskDone.removeAt(index);
    });
  }

  // ─── RESET FORM ────────────────────────────────────────────────
  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    setState(() {
      _selectedDeadline = null;
      _selectedReminder = null;
      _selectedCategory = null;
      _subtaskControllers = [TextEditingController()];
      _subtaskDone = [false];
    });
  }

  // ─── PILIH CATEGORY ────────────────────────────────────────────
  Future<void> _pickCategory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoryPage(),
      ),

    );
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
    }
  }

  // ─── PILIH REMINDER ────────────────────────────────────────────
  Future<void> _pickReminder() async {
    final result = await Navigator.push<DateTime?>(
      context,
      MaterialPageRoute(
        builder: (_) => const ReminderPage(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedReminder = result);
    }
  }
  // ─── SIMPAN TASK KE FIRESTORE + JADWALKAN NOTIFIKASI ────────────
  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama task tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dashboard mengurutkan & menampilkan task berdasarkan field 'date',
    // jadi deadline wajib diisi — kalau tidak, task ini tidak akan pernah
    // muncul di daftar "Upcoming tasks".
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dashboard menampilkan category langsung lewat Text(task["category"]),
    // yang akan error kalau nilainya null.
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum login'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Bangun list subtask — lewati subtask yang judulnya dibiarkan kosong
      final subtaskList = List.generate(
        _subtaskControllers.length,
        (i) => {
          'title': _subtaskControllers[i].text.trim(),
          'done': _subtaskDone[i],
        },
      ).where((s) => (s['title'] as String).isNotEmpty).toList();

      // Simpan ke Firestore — listener di Dashboard akan otomatis
      // mendeteksi dokumen baru ini dan memperbarui tampilan secara real-time.
      final docRef = await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'description': _descController.text.trim(),
        'subtasks': subtaskList,
        'category': _selectedCategory,
        // 'date' dalam format ISO (yyyy-MM-dd) supaya orderBy("date") di
        // Dashboard mengurutkan tugas secara kronologis dengan benar.
        'date': _formatIsoDate(_selectedDeadline!),
        'deadline': Timestamp.fromDate(_selectedDeadline!),
        'reminder': _selectedReminder != null
            ? Timestamp.fromDate(_selectedReminder!)
            : null,
        // Flag terpisah supaya gampang di-query oleh halaman notifikasi
        // (Firestore agak rumit kalau query langsung pakai != null).
        'hasReminder': _selectedReminder != null,
        // 'uid' (bukan 'userId') — samakan dengan field yang dipakai
        // dashboard.dart untuk memfilter task milik user yang login.
        'uid': user.uid,
        'createdAt': Timestamp.now(),
      });

      // Jadwalkan local notification kalau reminder diset. Notifikasi ini
      // akan tetap muncul di notification tray HP walau aplikasi ditutup.
      if (_selectedReminder != null) {
        await NotificationService().scheduleNotification(
          id: NotificationService.idFromDocId(docRef.id),
          title: 'Reminder: $title',
          body: _descController.text.trim().isEmpty
              ? 'Jangan lupa kerjakan task ini'
              : _descController.text.trim(),
          scheduledDate: _selectedReminder!,
        );
      }

      // Tampilkan SnackBar SEBELUM pop agar context masih valid.
      // Gunakan mounted guard untuk keamanan ekstra.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task berhasil disimpan ✓'),
          backgroundColor: Color(0xFF2F6FED),
          duration: Duration(seconds: 2),
        ),
      );

      // Reset form (kalau AddTaskPage ditampilkan sebagai tab di dalam
      // Dashboard, cukup reset — tidak perlu pop).
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── PILIH DEADLINE ────────────────────────────────────────────
  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDeadline = picked);
    }
  }

  // Format tanggal jadi String ISO "yyyy-MM-dd" (zero-padded) supaya
  // Firestore .orderBy("date") di Dashboard mengurutkan tugas secara
  // kronologis dengan benar (string "2/6/2026" vs "10/6/2026" akan
  // terurut salah kalau tidak di-pad seperti ini).
  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ─── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // AppBar hanya tampil jika halaman ini di-push sebagai route baru
      // (bukan sebagai tab). Jika ingin selalu tampil, hapus kondisi ini.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Dashboard sudah punya nav bar
        title: const Text(
          'Add Task',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER CARD ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TITLE
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nama Task',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const Divider(color: Colors.white30, height: 16),
                  // DESCRIPTION
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Deskripsi (opsional)',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── DEADLINE ───────────────────────────────────────────
            _buildMenuTile(
              icon: Icons.calendar_today,
              title: 'Deadline Task',
              subtitle: _selectedDeadline == null
                  ? 'Pilih deadline'
                  : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
              onTap: _pickDeadline,
              trailing: _selectedDeadline != null
                  ? GestureDetector(
                      onTap: () => setState(() => _selectedDeadline = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                    )
                  : null,
            ),

            // ── CATEGORY ───────────────────────────────────────────
            _buildMenuTile(
              icon: Icons.folder_outlined,
              title: 'Category',
              subtitle: _selectedCategory ?? 'Pilih category',
              onTap: _pickCategory,
            ),

            // ── REMINDER ───────────────────────────────────────────
            _buildMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Reminder',
              subtitle: _selectedReminder == null
                  ? 'Pilih reminder'
                  : '${_selectedReminder!.day}/${_selectedReminder!.month}/${_selectedReminder!.year} '
                      '${_selectedReminder!.hour.toString().padLeft(2, '0')}:${_selectedReminder!.minute.toString().padLeft(2, '0')}',
              onTap: _pickReminder,
              trailing: _selectedReminder != null
                  ? GestureDetector(
                      onTap: () => setState(() => _selectedReminder = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            // ── SUBTASKS ───────────────────────────────────────────
            const Text(
              'Subtasks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),

            Column(
              children: List.generate(_subtaskControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _subtaskDone[i],
                        onChanged: (val) =>
                            setState(() => _subtaskDone[i] = val!),
                        activeColor: const Color(0xFF2F6FED),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _subtaskControllers[i],
                          decoration: InputDecoration(
                            hintText: 'Subtask ${i + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      // Hapus subtask (hanya tampil jika ada lebih dari 1)
                      if (_subtaskControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _removeSubtask(i),
                        ),
                    ],
                  ),
                );
              }),
            ),

            // ── ADD SUBTASK BUTTON ──────────────────────────────────
            OutlinedButton.icon(
              onPressed: _addSubtask,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Subtask'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2F6FED),
                side: const BorderSide(color: Color(0xFF2F6FED)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── SAVE BUTTON ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6FED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan Task',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),

      // ❌ TIDAK ada BottomNavigationBar di sini —
      // sudah dikelola oleh Dashboard (menghindari duplikasi nav bar).
    );
  }

  // ─── HELPER: MENU TILE ─────────────────────────────────────────
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2F6FED)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}