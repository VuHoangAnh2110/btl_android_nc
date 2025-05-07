import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nguoi.dart';

class NguoiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'tblNguoi';

  // Lấy danh sách nguoi từ Firestore
  Stream<List<Nguoi>> getNguoiList() {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Nguoi.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Thêm người mới
  Future<DocumentReference> addNguoi(Nguoi nguoi) {
    return _firestore.collection(collection).add(nguoi.toMap());
  }

  // Cập nhật thông tin người
  Future<void> updateNguoi(String id, Nguoi nguoi) {
    return _firestore.collection(collection).doc(id).update(nguoi.toMap());
  }

  // Xóa nguoi
  Future<void> deleteNguoi(String id) {
    return _firestore.collection(collection).doc(id).delete();
  }

  // Tìm kiếm người theo tên
  Stream<List<Nguoi>> searchNguoiByName(String name) {
    return _firestore
        .collection(collection)
        .where('name', isEqualTo: name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Nguoi.fromMap(doc.id, doc.data()))
            .toList());
  }

}