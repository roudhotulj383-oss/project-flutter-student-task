import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/Category_services.dart';

class _CC {
  static const primary       = Color(0xFF4A6CF7);
  static const primaryLight  = Color(0xFF6A85F7);
  static const primaryDark   = Color(0xFF3557E5);
  static const danger        = Color(0xFFFF4757);
  static const success       = Color(0xFF2ED573);

  static Color bg(bool d)          => d ? const Color(0xFF0F0F1A) : const Color(0xFFF0F3FF);
  static Color card(bool d)        => d ? const Color(0xFF1C1C2E) : Colors.white;
  static Color textPrimary(bool d) => d ? Colors.white : const Color(0xFF1A1A2E);
  static Color textSub(bool d)     => d ? Colors.grey.shade400 : Colors.grey.shade600;
  static Color border(bool d)      => d ? Colors.grey.shade800 : Colors.grey.shade200;
  static Color inputFill(bool d)   => d ? const Color(0xFF2A2A40) : const Color(0xFFF8F9FF);
}


class CategoryPage extends StatefulWidget {
  
  final bool selectMode;
  const CategoryPage({super.key, this.selectMode = false});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  final CategoryService _svc = CategoryService();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ─── SNACKBAR ────────────────────────────────────────────────────────────
  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: ok ? _CC.success : _CC.danger,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ─── TEXT FIELD HELPER ───────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      style: TextStyle(color: _CC.textPrimary(isDark), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _CC.textSub(isDark), fontSize: 13),
        prefixIcon: Icon(icon, color: _CC.primary, size: 20),
        filled: true,
        fillColor: _CC.inputFill(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _CC.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CC.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CC.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CC.danger, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dialogTitle({
    required String text,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: _CC.textPrimary(isDark),
          ),
        ),
      ],
    );
  }

  // ─── DIALOG: TAMBAH ───────────────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool saving    = false;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: _CC.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogTitle(
                    text: 'Tambah Kategori',
                    icon: Icons.create_new_folder_rounded,
                    iconColor: _CC.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    ctrl: nameCtrl,
                    label: 'Nama Kategori',
                    icon: Icons.label_outline_rounded,
                    isDark: isDark,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    ctrl: descCtrl,
                    label: 'Deskripsi (opsional)',
                    icon: Icons.notes_rounded,
                    isDark: isDark,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: _CC.border(isDark)),
                          ),
                          child: Text('Batal',
                              style:
                                  TextStyle(color: _CC.textSub(isDark))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate())
                                    return;
                                  setDlg(() => saving = true);
                                  try {
                                    await _svc.addCategory(
                                      name: nameCtrl.text,
                                      description: descCtrl.text,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _snack('Kategori berhasil ditambahkan',
                                        ok: true);
                                  } catch (e) {
                                    setDlg(() => saving = false);
                                    _snack('Gagal: $e', ok: false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _CC.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Simpan',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Future<void> _showEditDialog(
      String id, String curName, String curDesc) async {
    final nameCtrl = TextEditingController(text: curName);
    final descCtrl = TextEditingController(text: curDesc);
    final formKey  = GlobalKey<FormState>();
    bool saving    = false;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: _CC.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogTitle(
                    text: 'Edit Kategori',
                    icon: Icons.edit_rounded,
                    iconColor: _CC.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    ctrl: nameCtrl,
                    label: 'Nama Kategori',
                    icon: Icons.label_outline_rounded,
                    isDark: isDark,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    ctrl: descCtrl,
                    label: 'Deskripsi (opsional)',
                    icon: Icons.notes_rounded,
                    isDark: isDark,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: _CC.border(isDark)),
                          ),
                          child: Text('Batal',
                              style:
                                  TextStyle(color: _CC.textSub(isDark))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate())
                                    return;
                                  setDlg(() => saving = true);
                                  try {
                                    await _svc.updateCategory(
                                      id: id,
                                      name: nameCtrl.text,
                                      description: descCtrl.text,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _snack('Kategori berhasil diperbarui',
                                        ok: true);
                                  } catch (e) {
                                    setDlg(() => saving = false);
                                    _snack('Gagal memperbarui: $e',
                                        ok: false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _CC.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Update',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Future<void> _showDeleteDialog(
      String id, String name, int taskCount) async {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    bool deleting = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: _CC.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _CC.danger.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: _CC.danger,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hapus Kategori?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _CC.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                if (taskCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _CC.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _CC.danger.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: _CC.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kategori ini masih memiliki $taskCount tugas. Hapus atau pindahkan tugas terlebih dahulu.',
                            style: TextStyle(
                              color: _CC.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Text(
                    'Yakin ingin menghapus "$name"?\nTindakan ini tidak dapat dibatalkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _CC.textSub(isDark),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            deleting ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: _CC.border(isDark)),
                        ),
                        child: Text('Batal',
                            style:
                                TextStyle(color: _CC.textSub(isDark))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (deleting || taskCount > 0)
                            ? null
                            : () async {
                                setDlg(() => deleting = true);
                                try {
                                  final stillHasTasks =
                                      await _svc.hasTasks(id);
                                  if (stillHasTasks) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _snack(
                                      'Hapus tugas dalam kategori ini terlebih dahulu.',
                                      ok: false,
                                    );
                                    return;
                                  }
                                  await _svc.deleteCategory(id);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _snack(
                                      'Kategori "$name" berhasil dihapus',
                                      ok: true);
                                } catch (e) {
                                  setDlg(() => deleting = false);
                                  _snack('Gagal menghapus: $e', ok: false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _CC.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _CC.danger.withOpacity(0.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Hapus',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _CC.bg(isDark),
      appBar: AppBar(
        backgroundColor: _CC.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.selectMode ? 'Pilih Kategori' : 'Kategori',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_CC.primaryDark, _CC.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _svc.getCategories(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _CC.primary),
            );
          }
          if (snap.hasError) return _buildErrorState(isDark);
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data();
              return FutureBuilder<int>(
                future: _svc.getTaskCount(doc.id),
                builder: (context, tSnap) {
                  final count = tSnap.data ?? 0;
                  return _CategoryCard(
                    isDark: isDark,
                    id: doc.id,
                    name: data['name'] ?? '',
                    description: data['description'] ?? '',
                    taskCount: count,
                    loadingCount: !tSnap.hasData,
                    selectMode: widget.selectMode,
                    // ✅ FIX: Tombol + → kembalikan nama kategori ke AddTaskPage
                    onSelect: () =>
                        Navigator.pop(context, data['name'] ?? ''),
                    onEdit: () => _showEditDialog(
                        doc.id,
                        data['name'] ?? '',
                        data['description'] ?? ''),
                    onDelete: () => _showDeleteDialog(
                        doc.id, data['name'] ?? '', count),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          backgroundColor: _CC.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Tambah Kategori',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _CC.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 52,
                color: _CC.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _CC.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + di bawah untuk membuat kategori pertamamu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: _CC.textSub(isDark), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: _CC.textSub(isDark)),
          const SizedBox(height: 14),
          Text('Gagal memuat kategori',
              style: TextStyle(color: _CC.textSub(isDark), fontSize: 14)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final bool isDark;
  final String id;
  final String name;
  final String description;
  final int taskCount;
  final bool loadingCount;
  final bool selectMode;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.isDark,
    required this.id,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.loadingCount,
    required this.selectMode,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _CC.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _CC.border(isDark), width: isDark ? 1 : 0),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: _CC.primary.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Ikon folder ──────────────────────────
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_CC.primary, _CC.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _CC.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.folder_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),

            // ── Teks ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _CC.textPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 12,
                          color: _CC.textSub(isDark),
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: loadingCount
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 60,
                            height: 20,
                            child: LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(10),
                              color: _CC.primary.withOpacity(0.4),
                              backgroundColor:
                                  _CC.primary.withOpacity(0.1),
                            ),
                          )
                        : _TaskBadge(
                            key: ValueKey(taskCount),
                            count: taskCount,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

      
            Column(
              children: [
                
                _ActionBtn(
                  icon: selectMode
                      ? Icons.add_circle_rounded
                      : Icons.edit_rounded,
                  color: _CC.primary,
                  isDark: isDark,
                  onTap: selectMode ? onSelect : onEdit,
                ),
                const SizedBox(height: 8),
                
                if (selectMode)
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: Colors.orange,
                    isDark: isDark,
                    onTap: onEdit,
                  )
                else
                  _ActionBtn(
                    icon: Icons.delete_rounded,
                    color: _CC.danger,
                    isDark: isDark,
                    onTap: onDelete,
                  ),
                
                if (selectMode) ...[
                  const SizedBox(height: 8),
                  _ActionBtn(
                    icon: Icons.delete_rounded,
                    color: _CC.danger,
                    isDark: isDark,
                    onTap: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final int count;
  const _TaskBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final hasTask = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasTask
            ? _CC.primary.withOpacity(0.12)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        hasTask ? '$count Tugas' : 'Tidak ada tugas',
        style: TextStyle(
          color: hasTask ? _CC.primary : Colors.grey,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}