import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tìm người dùng đã đăng nhập
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    try {
      final querySnapshot = await _db.collection('users').get();

      for (var doc in querySnapshot.docs) {
        if (doc.data().containsKey('isLoggedIn') && doc['isLoggedIn'] == true) {
          return {
            'userData': doc.data() as Map<String, dynamic>,
            'userId': doc.id,
          };
        }
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      return null;
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Số điện thoại hoặc mật khẩu không đúng'
        };
      }

      final userDoc = querySnapshot.docs.first;
      await _db
          .collection('users')
          .doc(userDoc.id)
          .update({'isLoggedIn': true});

      final userData = userDoc.data();
      final bool isAdmin = userData.containsKey('isAdmin')
          ? userData['isAdmin'] ?? false
          : false;

      return {
        'success': true,
        'isAdmin': isAdmin,
        'userData': userData,
        'message': isAdmin
            ? 'Đăng nhập thành công với quyền Admin!'
            : 'Đăng nhập thành công!'
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Đăng xuất
  Future<bool> logout(String phone) async {
    try {
      final querySnapshot =
          await _db.collection('users').where('phone', isEqualTo: phone).get();

      if (querySnapshot.docs.isNotEmpty) {
        await _db
            .collection('users')
            .doc(querySnapshot.docs.first.id)
            .update({'isLoggedIn': false});
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      return false;
    }
  }
}
