import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';

class AdminUsersTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const AdminUsersTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có người dùng nào'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var userData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var userId = snapshot.data!.docs[index].id;

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(52),
                  child: Text(
                    userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                title: Text(
                  userData['name'] ?? 'Người dùng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SĐT: ${userData['phone'] ?? 'Không có'}'),
                    Row(
                      children: [
                        Icon(
                          userData['isAdmin'] == true
                              ? Icons.verified
                              : Icons.person,
                          size: 14,
                          color: userData['isAdmin'] == true
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          userData['isAdmin'] == true
                              ? 'Quản trị viên'
                              : 'Người dùng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: userData['isAdmin'] == true
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      // Xóa người dùng
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Xác nhận'),
                          content: Text('Bạn có chắc muốn xóa người dùng này?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  await db
                                      .collection('users')
                                      .doc(userId)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Đã xóa người dùng thành công')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Lỗi khi xóa người dùng: $e')),
                                  );
                                }
                              },
                              child: Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'toggleAdmin') {
                      // Chuyển đổi quyền admin
                      bool currentAdminStatus = userData['isAdmin'] == true;
                      try {
                        await db.collection('users').doc(userId).update({
                          'isAdmin': !currentAdminStatus,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(currentAdminStatus
                                ? 'Đã thu hồi quyền quản trị viên'
                                : 'Đã cấp quyền quản trị viên'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi cập nhật quyền: $e')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggleAdmin',
                      child: Row(
                        children: [
                          Icon(userData['isAdmin'] == true
                              ? Icons.person
                              : Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text(userData['isAdmin'] == true
                              ? 'Thu hồi quyền admin'
                              : 'Cấp quyền admin'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa người dùng'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
