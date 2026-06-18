import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_task.dart';
import 'calendar.dart';
import 'setting/setting.dart';
import 'notification_bell.dart';
import '../Services/notification_services.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final user = FirebaseAuth.instance.currentUser;

  int currentIndex = 0;

  Widget _buildHomeTab() {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("uid", isEqualTo: user?.uid)
            .orderBy("date")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

    
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Gagal memuat data:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // HEADER
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/welcome.png",
                        width: 35,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "StudentTask",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      NotificationBell(snapshot: snapshot.data!),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? "U",
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 35),

                  
                  Text(
                    "Hello, ${user?.displayName ?? user?.email?.split('@')[0]}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 30),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Stay productive today",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 25),

                  
                  // CARD
                
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Today's tasks",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Icon(Icons.bolt, size: 15, color: Colors.blue),
                            const SizedBox(width: 5),
                            Text(
                              "Live sync",
                              style: TextStyle(color: Colors.blue),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${tasks.length}",
                                style: const TextStyle(
                                    fontSize: 42,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: " tugas akan datang",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blue),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  
            
                  
                  Row(
                    children: [
                      const Text(
                        "Upcoming tasks",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const Spacer(),
                      Icon(Icons.sync, size: 18, color: Colors.grey),
                      const SizedBox(width: 5),
                      const Text("Synced")
                    ],
                  ),

                  const SizedBox(height: 20),

                  // EMPTY
                  
                  if (tasks.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 15),
                            const Text(
                              "Belum ada tugas",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Tap + di bawah untuk menambah tugas",
                              style: TextStyle(color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskItem(task);
                      },
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(QueryDocumentSnapshot task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
  
      confirmDismiss: (_) => _confirmDeleteTask(task),
      onDismissed: (_) => _deleteTask(task),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.task_alt, color: Colors.blue),
          ),
          title: Text(task["title"] ?? ''),
          subtitle: Text(task["category"] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task["date"] ?? ''),
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: Colors.blue),
                onPressed: () => _editTaskDialog(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Future<bool> _confirmDeleteTask(QueryDocumentSnapshot task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Tugas'),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus tugas "${task["title"]}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ─── HAPUS TASK DARI FIRESTORE + BATALKAN REMINDER-NYA ──────────────────
  Future<void> _deleteTask(QueryDocumentSnapshot task) async {
    try {
      // Batalkan notifikasi reminder milik task ini (kalau ada), supaya
      // tidak ada notifikasi nyasar untuk task yang sudah dihapus.
      await NotificationService().cancelNotificationByDocId(task.id);
      await task.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "${task["title"]}" dihapus'),
            backgroundColor: const Color(0xFF2ED573),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus tugas: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  
  Future<void> _editTaskDialog(QueryDocumentSnapshot task) async {
    final titleController =
        TextEditingController(text: task["title"] ?? '');
    final categoryController =
        TextEditingController(text: task["category"] ?? '');


    DateTime selectedDate =
        DateTime.tryParse(task["date"]?.toString() ?? '') ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Nama Tugas',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Nama tugas wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Category wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Deadline',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        
                        final year =
                            selectedDate.year.toString().padLeft(4, '0');
                        final month =
                            selectedDate.month.toString().padLeft(2, '0');
                        final day =
                            selectedDate.day.toString().padLeft(2, '0');

                        await task.reference.update({
                          'title': titleController.text.trim(),
                          'category': categoryController.text.trim(),
                          'date': '$year-$month-$day',
                          'deadline': Timestamp.fromDate(selectedDate),
                        });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tugas berhasil diperbarui'),
                              backgroundColor: Color(0xFF2ED573),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal memperbarui tugas: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final tabs = [
      _buildHomeTab(),
      const CalendarPage(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),

      bottomNavigationBar: BottomAppBar(
       
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => setState(() => currentIndex = 0),
                icon: Icon(
                  Icons.home,
                  color: currentIndex == 0 ? Colors.blue : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 1),
                icon: Icon(
                  Icons.calendar_today,
                  color: currentIndex == 1 ? Colors.blue : Colors.grey,
                ),
              ),
              
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTaskPage()),
                  );
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 2),
                icon: Icon(
                  Icons.settings,
                  color: currentIndex == 2 ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}