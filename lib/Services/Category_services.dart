import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════
  // GET ALL CATEGORIES
  // ══════════════════════════════════════════════
  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ══════════════════════════════════════════════
  // ADD CATEGORY
  // ══════════════════════════════════════════════
  Future<void> addCategory({
    required String name,
    required String description,
  }) async {
    await _firestore.collection('categories').add({
      'name': name.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════
  // UPDATE CATEGORY
  // ══════════════════════════════════════════════
  Future<void> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    await _firestore.collection('categories').doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════
  // DELETE CATEGORY
  // ══════════════════════════════════════════════
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // ══════════════════════════════════════════════
  // CHECK CATEGORY HAS TASKS
  // ✅ FIX: query pakai field 'category' (nama string),
  //         bukan 'categoryId' — sesuai yang disimpan add_task.dart
  // ══════════════════════════════════════════════
  Future<bool> hasTasks(String categoryId) async {
    // Ambil nama kategori dulu dari ID-nya
    final catDoc =
        await _firestore.collection('categories').doc(categoryId).get();
    if (!catDoc.exists) return false;
    final categoryName = catDoc.data()?['name'] as String? ?? '';

    final snapshot = await _firestore
        .collection('tasks')
        .where('category', isEqualTo: categoryName)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ══════════════════════════════════════════════
  // GET TASK COUNT PER CATEGORY
  // ✅ FIX: query pakai field 'category' (nama string),
  //         bukan 'categoryId'
  // ══════════════════════════════════════════════
  Future<int> getTaskCount(String categoryId) async {
    // Ambil nama kategori dulu dari ID-nya
    final catDoc =
        await _firestore.collection('categories').doc(categoryId).get();
    if (!catDoc.exists) return 0;
    final categoryName = catDoc.data()?['name'] as String? ?? '';

    final snapshot = await _firestore
        .collection('tasks')
        .where('category', isEqualTo: categoryName)
        .get();

    return snapshot.docs.length;
  }

  // ══════════════════════════════════════════════
  // GET CATEGORY BY ID
  // ══════════════════════════════════════════════
  Future<DocumentSnapshot<Map<String, dynamic>>> getCategoryById(
      String categoryId) async {
    return await _firestore.collection('categories').doc(categoryId).get();
  }
}