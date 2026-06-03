import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference tasks =
      FirebaseFirestore.instance.collection('tasks');

  // Tambah Task
  Future<void> addTask(String title) async {
    await tasks.add({
      'title': title,
      'createdAt': Timestamp.now(),
    });
  }

  // Hapus Task
  Future<void> deleteTask(String id) async {
    await tasks.doc(id).delete();
  }

  // Update Task
  Future<void> updateTask(String id, String newTitle) async {
    await tasks.doc(id).update({
      'title': newTitle,
    });
  }
}