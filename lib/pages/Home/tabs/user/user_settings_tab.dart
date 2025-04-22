import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../widgets/common/info_item.dart';
import '../../../../widgets/common/option_item.dart';

class UserSettingsTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;
  final Function() onLogout;

  const UserSettingsTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isLoggedIn)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Bạn chưa đăng nhập',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/dangnhap');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Ảnh đại diện
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(52),
                  child: Text(
                    userData?['name']?.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Tên người dùng
                Text(
                  userData?['name'] ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Badge Admin nếu có
                if (userData?.containsKey('isAdmin') == true &&
                    userData?['isAdmin'] == true)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Quản trị viên',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 30),

                // Thông tin chi tiết
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Tiêu đề
                        Text(
                          'Thông tin cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Divider(height: 30),

                        // Số điện thoại
                        InfoItem(
                          icon: Icons.phone,
                          title: 'Số điện thoại',
                          value: userData?['phone'] ?? 'Không có',
                        ),

                        // Ngày tạo tài khoản
                        InfoItem(
                          icon: Icons.calendar_today,
                          title: 'Ngày tạo tài khoản',
                          value: userData?['created_at'] != null
                              ? DateFormatter.formatDate(
                                  userData?['created_at'])
                              : 'Không có thông tin',
                        ),

                        // Trạng thái
                        InfoItem(
                          icon: Icons.verified_user,
                          title: 'Trạng thái',
                          value: 'Đang hoạt động',
                          valueColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Các tùy chọn
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      OptionItem(
                        icon: Icons.security,
                        title: 'Đổi mật khẩu',
                        onTap: () {
                          // Xử lý đổi mật khẩu
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Thông báo'),
                              content: Text(
                                  'Tính năng đổi mật khẩu sẽ sớm được cập nhật!'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Divider(height: 1),
                      OptionItem(
                        icon: Icons.edit,
                        title: 'Chỉnh sửa thông tin',
                        onTap: () {
                          // Xử lý chỉnh sửa thông tin
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Thông báo'),
                              content: Text(
                                  'Tính năng chỉnh sửa thông tin sẽ sớm được cập nhật!'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Divider(height: 1),
                      OptionItem(
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Đăng xuất'),
                                content:
                                    Text('Bạn có chắc chắn muốn đăng xuất?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onLogout();
                                    },
                                    child: Text('Đăng xuất'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
