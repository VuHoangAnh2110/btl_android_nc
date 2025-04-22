import 'package:flutter/material.dart';

class AdminHomeTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const AdminHomeTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Đây là trang quản trị viên', style: TextStyle(fontSize: 18)),
    );
  }
}
