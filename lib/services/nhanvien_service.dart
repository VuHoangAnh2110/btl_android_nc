import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nhanvien.dart';

class NhanVienService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'tblnhanvien';

  // Lấy danh sách nhân viên từ Firestore, sắp xếp theo tên
  Stream<List<NhanVien>> getNhanVienList() {
    return _firestore
        .collection(collection)
        .orderBy('hoTen') // Sắp xếp theo tên
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NhanVien.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Thêm nhân viên mới
  Future<DocumentReference> addNhanVien(NhanVien nhanVien) {
    return _firestore.collection(collection).add(nhanVien.toMap());
  }

  // Kiểm tra mã nhân viên đã tồn tại hay chưa
  Future<bool> isMaNhanVienExists(String maNhanVien) async {
    final QuerySnapshot result = await _firestore
        .collection(collection)
        .where('maNhanVien', isEqualTo: maNhanVien)
        .limit(1)
        .get();
    
    return result.docs.isNotEmpty;
  }
}