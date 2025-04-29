import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin AdminPermissionMixin<T extends StatefulWidget> on State<T> {
  void checkAdminPermission(
      BuildContext context, Map<String, dynamic>? userData, bool isLoggedIn) async {
    bool hasAdminRights = false;
    
    // Kiểm tra quyền admin từ userData
    if (isLoggedIn && userData != null && userData['isAdmin'] == true) {
      hasAdminRights = true;
    }
    
    // Nếu không tìm thấy trong userData, kiểm tra trong SharedPreferences
    if (!hasAdminRights) {
      final prefs = await SharedPreferences.getInstance();
      hasAdminRights = prefs.getBool('isAdmin') ?? false;
    }
    
    // Nếu không có quyền admin, chuyển hướng đến trang đăng nhập
    if (!hasAdminRights) {
      // Wait until build is complete before navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to login page
        Navigator.of(context).pushReplacementNamed('/dangnhap');

        // Show message explaining why they were redirected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần đăng nhập với tài khoản quản trị để truy cập'),
          ),
        );
      });
    }
  }
}
