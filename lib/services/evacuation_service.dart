import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evacuation_area.dart';

class EvacuationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'evacuation_areas';

  // Thêm khu vực di tản mới
  Future<String> addEvacuationArea(EvacuationArea area) async {
    try {
      final docRef = await _firestore.collection(_collection).add(area.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding evacuation area: $e');
      throw e;
    }
  }

  // Lấy danh sách khu vực di tản
  Stream<List<EvacuationArea>> getEvacuationAreas() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvacuationArea.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Lấy khu vực di tản theo ID
  Future<EvacuationArea?> getEvacuationAreaById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return EvacuationArea.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting evacuation area: $e');
      throw e;
    }
  }

  // Cập nhật khu vực di tản
  Future<void> updateEvacuationArea(String id, EvacuationArea area) async {
    try {
      await _firestore.collection(_collection).doc(id).update(area.toMap());
    } catch (e) {
      print('Error updating evacuation area: $e');
      throw e;
    }
  }

  // Xóa khu vực di tản
  Future<void> deleteEvacuationArea(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting evacuation area: $e');
      throw e;
    }
  }
}