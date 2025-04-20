import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btl_android_nc/services/notification_service.dart';
import 'package:btl_android_nc/services/firebase_messaging_service.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class Home extends StatefulWidget {
  final bool isAdmin;

  Home({this.isAdmin = false});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      // Lấy thông tin người dùng hiện tại (nếu có)
      final querySnapshot = await db.collection('users').get();

      if (querySnapshot.docs.isNotEmpty) {
        // Tìm người dùng đã đăng nhập
        QueryDocumentSnapshot? loggedInUser;
        
        for (var doc in querySnapshot.docs) {
          // Kiểm tra có trường isLoggedIn hay không
          if (doc.data().containsKey('isLoggedIn') && doc['isLoggedIn'] == true) {
            loggedInUser = doc;
            break;
          }
        }

        setState(() {
          if (loggedInUser != null) {
            userData = loggedInUser.data() as Map<String, dynamic>;
            isLoggedIn = true;
          } else {
            userData = null;
            isLoggedIn = false;
          }
        });
      } else {
        setState(() {
          userData = null;
          isLoggedIn = false;
        });
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      setState(() {
        userData = null;
        isLoggedIn = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      if (userData != null && userData!.containsKey('phone')) {
        // Tìm người dùng theo số điện thoại để đăng xuất
        final querySnapshot = await db
            .collection('users')
            .where('phone', isEqualTo: userData!['phone'])
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          // Cập nhật trạng thái đăng xuất
          await db.collection('users').doc(userDoc.id).update({'isLoggedIn': false});
        }
      }

      setState(() {
        userData = null;
        isLoggedIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thành công')),
      );
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất không thành công: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Trang quản trị' : 'Trang chủ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Hiển thị badge hoặc icon riêng cho admin
          if (widget.isAdmin)
            Icon(Icons.admin_panel_settings),
          // Nút đăng xuất
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Hiển thị hộp thoại xác nhận đăng xuất
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Đăng xuất'),
                    content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await logout();
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
      
      // Hiển thị nội dung khác nhau dựa trên quyền admin
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.isAdmin 
            ? [
                // Các tab cho admin
                buildAdminHomeTab(),
                buildAdminManageUsersTab(),
                buildSettingsTab(),
              ]
            : [
                // Các tab cho người dùng thường
                buildHomeTab(),
                buildProfileTab(),
                buildSettingsTab(),
              ],
      ),
      
      // Bottom navigation với các mục khác nhau cho admin và người dùng thường
      bottomNavigationBar: BottomNavigationBar(
        items: widget.isAdmin
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Tổng quan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Quản lý người dùng',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Cài đặt',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Tài khoản',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Cài đặt',
                ),
              ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      
      // SOS button cho cả admin và người dùng thường
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('SOS'),
                content: Text('Bạn đã gửi yêu cầu cứu trợ khẩn cấp!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        },
        label: Text('SOS'),
        icon: Icon(Icons.warning, color: Colors.white),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Widget cho tab Trang chủ
  Widget buildHomeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner chào mừng
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn 
                      ? 'Chào mừng, ${userData?['name'] ?? 'Người dùng'}!'
                      : 'Chào mừng đến với ứng dụng Hỗ Trợ Thiên Tai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10),
                if (isLoggedIn)
                  Text(
                    'Số điện thoại: ${userData?['phone'] ?? 'Không có'}',
                    style: TextStyle(fontSize: 16),
                  )
                else
                  Text(
                    'Hãy đăng nhập để sử dụng đầy đủ các tính năng',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),

          // Phần còn lại của code giữ nguyên
          SizedBox(height: 30),
          // Các tính năng chính
          Text(
            'Tính năng chính',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          // Giữ nguyên phần code GridView và ListView...
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              buildFeatureCard(
                icon: Icons.volunteer_activism,
                title: 'Quyên góp',
                color: Colors.orangeAccent,
                onTap: () {
                  // Xử lý tính năng quyên góp
                },
              ),
              buildFeatureCard(
                icon: Icons.location_on,
                title: 'Điểm cứu trợ',
                color: Colors.greenAccent,
                onTap: () {
                  // Xử lý tính năng điểm cứu trợ
                },
              ),
              buildFeatureCard(
                icon: Icons.message,
                title: 'Nhắn tin hỗ trợ',
                color: Colors.blueAccent,
                onTap: () {
                  // Xử lý tính năng nhắn tin
                },
              ),
              buildFeatureCard(
                icon: Icons.directions_boat,
                title: 'Yêu cầu cứu hộ',
                color: Colors.redAccent,
                onTap: () {
                  // Xử lý tính năng cứu hộ
                },
              ),
            ],
          ),

          SizedBox(height: 30),

          // Tin tức mới nhất
          Text(
            'Tin tức mới nhất',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),

          // Danh sách tin tức
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3, // Số lượng tin tức
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[500]),
                  ),
                  title: Text(
                    'Tin tức ${index + 1}: Cứu trợ tại miền Trung',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Cập nhật về tình hình thiên tai và các hoạt động cứu trợ...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Xử lý khi nhấn vào tin tức
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget cho tính năng
  Widget buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho tab Tài khoản
  Widget buildProfileTab() {
    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dangnhap').then((_) {
                  fetchUserData();
                });
              },
              child: Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
    }

    // Nếu đã đăng nhập, hiển thị thông tin tài khoản
    return Center(
      child: Text('Thông tin tài khoản của ${userData?['name']}'),
    );
  }

  // Widget cho tab Cài đặt
  Widget buildSettingsTab() {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _bodyController = TextEditingController();
    final NotificationService _notificationService = NotificationService();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gửi thông báo đến người dùng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề thông báo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Nội dung thông báo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Hiển thị hộp thoại xác nhận
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Xác nhận gửi thông báo'),
                            content: Text('Bạn có chắc muốn gửi thông báo này đến tất cả người dùng?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  
                                  // Hiển thị loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                  
                                  try {
                                    // Gửi thông báo
                                    bool success = await _notificationService.sendNotification(
                                      title: _titleController.text,
                                      body: _bodyController.text,
                                      topic: 'all',
                                    );
                                    
                                    // Đóng loading dialog
                                    Navigator.pop(context);
                                    
                                    // Hiển thị kết quả
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success 
                                              ? 'Thông báo đã được gửi thành công!'
                                              : 'Không thể gửi thông báo. Vui lòng thử lại sau.',
                                        ),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                      ),
                                    );
                                    
                                    if (success) {
                                      // Xóa input nếu gửi thành công
                                      _titleController.clear();
                                      _bodyController.clear();
                                    }
                                  } catch (e) {
                                    // Đóng loading dialog
                                    Navigator.pop(context);
                                    
                                    // Hiển thị lỗi
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Text('Gửi'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.send),
                      label: Text('Gửi thông báo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Lịch sử thông báo đã gửi
          Text(
            'Lịch sử thông báo đã gửi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          
          StreamBuilder<QuerySnapshot>(
            stream: _notificationService.getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Chưa có thông báo nào được gửi'),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var notification = snapshot.data!.docs[index];
                  var data = notification.data() as Map<String, dynamic>;
                  Timestamp? sentAt = data['sentAt'] as Timestamp?;
                  
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        data['title'] ?? 'Không có tiêu đề',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['body'] ?? 'Không có nội dung'),
                          SizedBox(height: 5),
                          Text(
                            'Gửi đến: ${data['topic'] ?? 'all'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (sentAt != null)
                            Text(
                              'Thời gian: ${sentAt.toDate().toString()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Thêm các phương thức build cho admin
  Widget buildAdminHomeTab() {
    return Center(
      child: Text('Đây là trang quản trị viên', style: TextStyle(fontSize: 18)),
    );
  }
  
  Widget buildAdminManageUsersTab() {
    return Center(
      child: Text('Quản lý người dùng', style: TextStyle(fontSize: 18)),
    );
  }
}
