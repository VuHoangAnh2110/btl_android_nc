import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:btl_android_nc/services/notification_service.dart';
import 'package:btl_android_nc/services/firebase_messaging_service.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

// Cấu trúc dữ liệu 
// users: Thông tin người dùng (name, phone, password, isAdmin, isLoggedIn)
// reliefRequests gồm có title, description, location, status, userId, createdAt
// notifications: Thông báo đã gửi


//Khai báo một StatefulWidget cho trang Home
class Home extends StatefulWidget {
  final bool isAdmin;
  // Constructor cho Home, có thể nhận tham số isAdmin
  // để xác định xem người dùng có phải là admin hay không
  Home({this.isAdmin = false});
  @override
  //Nơi chứa trạng thái và UI của widget
  // Trạng thái này sẽ được quản lý bởi lớp _HomeState
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Chỉ số của tab hiện tại 
  Map<String, dynamic>? userData; // Dữ liệu người dùng đã đăng nhập
  bool isLoggedIn = false; // Biến để theo dõi trạng thái đăng nhập
  bool isActuallyAdmin = false; // Biến mới để theo dõi quyền admin thực tế


  
  // Thêm các controller vào đây - là thuộc tính của lớp
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() { //Widget khởi tạo lần đầu tiên 
    super.initState();
    fetchUserData();
    
    // Khởi tạo các controller
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }
  
  @override
  void dispose() {
    // Giải phóng các controller khi widget bị hủy
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      final querySnapshot = await db.collection('users').get();
      // Tìm người dùng đã đăng nhập
      QueryDocumentSnapshot? loggedInUser;
      
      for (var doc in querySnapshot.docs) {
        if (doc.data().containsKey('isLoggedIn') && doc['isLoggedIn'] == true) {
          loggedInUser = doc;
          break;
        }
      }

      // Nếu tìm thấy người dùng đã đăng nhập, cập nhật dữ liệu
      // và trạng thái đăng nhập
      setState(() {
        if (loggedInUser != null) {
          userData = loggedInUser.data() as Map<String, dynamic>;
          isLoggedIn = true;
          
          // Cập nhật biến isActuallyAdmin dựa trên dữ liệu thực tế
          isActuallyAdmin = userData!.containsKey('isAdmin') && userData!['isAdmin'] == true;
        } else {
          userData = null;
          isLoggedIn = false;
          isActuallyAdmin = false;
        }
      });
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
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
      // reset trạng thái local 
      setState(() {
        userData = null;
        isLoggedIn = false;
        isActuallyAdmin = false; // Reset quyền admin khi đăng xuất
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
    // Sử dụng isActuallyAdmin thay vì widget.isAdmin nếu widget.isAdmin là false hoặc chưa có cột thông tin đó 
    bool showAdminInterface = widget.isAdmin || isActuallyAdmin;
    
    return Scaffold( // Scaffold là widget chính của trang
      appBar: AppBar(
        title: Text(showAdminInterface ? 'Trang quản trị' : 'Trang chủ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Hiển thị badge hoặc icon riêng cho admin
          if (showAdminInterface)
            Icon(Icons.admin_panel_settings),
            
          // Hiển thị nút đăng nhập/đăng xuất dựa trên trạng thái
          IconButton(
            icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
            onPressed: () {
              if (isLoggedIn) {
                // Hộp thoại xác nhận đăng xuất
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Đăng xuất'),
                      content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await logout();
                          },
                          child: Text('Đăng xuất'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Chuyển đến màn hình đăng nhập
                Navigator.pushNamed(context, '/dangnhap').then((_) {
                  fetchUserData(); // Cập nhật dữ liệu người dùng sau khi đăng nhập
                });
              }
            },
          ),
        ],
      ),
      
      // Hiển thị nội dung khác nhau dựa trên quyền admin
      body: IndexedStack( // chuyển đổi giữa các tab mà không làm mất trạng thái của chúng
        // Sử dụng IndexedStack để giữ lại trạng thái của các tab
        index: _selectedIndex,
        children: showAdminInterface 
            ? [
                // Các tab cho admin
                buildAdminUsersManagementTab(),
                buildAdminNotificationsTab(),
                buildAdminReliefRequestsTab(),
              ]
            : [
                // Các tab cho người dùng thường
                buildUserHomeTab(),
                buildUserReliefRequestTab(),
                buildUserSettingsTab(),
              ],
      ),
      
      // Bottom navigation với các mục khác nhau cho admin và người dùng thường
      bottomNavigationBar: BottomNavigationBar( // THanh điều hướng dưới cùng 
        items: showAdminInterface
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Quản lý người dùng',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active),
                  label: 'Gửi thông báo khẩn',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism),
                  label: 'Yêu cầu cứu trợ',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism),
                  label: 'Yêu cầu cứu trợ',
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
    // Banner chào mừng 
    // Bản đồ vùng thiên tai  
    // Tin tức thời tiết 
    // Danh sách yêu cầu cứu trợ
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

  // Định dạng ngày tháng từ Timestamp
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // Widget hiển thị từng mục thông tin
  Widget buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng tùy chọn
  Widget buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget cho tab Cài đặt
  

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

  // Quản lý người dùng
    // Hiển thị danh sách người dùng 
    // Cho phép xóa người dùng
    // Cho phép cấp quyền admin cho người dùng
  Widget buildAdminUsersManagementTab() {
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
            var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var userId = snapshot.data!.docs[index].id;
            
            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                          userData['isAdmin'] == true ? Icons.verified : Icons.person,
                          size: 14,
                          color: userData['isAdmin'] == true ? Colors.amber : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          userData['isAdmin'] == true ? 'Quản trị viên' : 'Người dùng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: userData['isAdmin'] == true ? Colors.amber : Colors.grey,
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
                                  await db.collection('users').doc(userId).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã xóa người dùng thành công')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi khi xóa người dùng: $e')),
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
                            content: Text(
                              currentAdminStatus 
                                  ? 'Đã thu hồi quyền quản trị viên' 
                                  : 'Đã cấp quyền quản trị viên'
                            ),
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
                          Icon(userData['isAdmin'] == true ? Icons.person : Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text(userData['isAdmin'] == true ? 'Thu hồi quyền admin' : 'Cấp quyền admin'),
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

  // Gửi thông báo khẩn cấp
    // Form gửi thông báo đến người dùng 
    // Lịch sử thông báo đã gửi
  Widget buildAdminNotificationsTab() {
    
    
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
                    'Gửi thông báo khẩn cấp',
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
                            title: Text('Xác nhận gửi thông báo khẩn cấp'),
                            content: Text('Bạn có chắc muốn gửi thông báo khẩn cấp này đến tất cả người dùng?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Lưu context gốc trước khi đóng dialog
                                  final originContext = context;
                                  Navigator.pop(context);
                                  
                                  // Tạo một biến để theo dõi dialog loading
                                  BuildContext? loadingDialogContext;
                                  
                                  // Hiển thị loading
                                  showDialog(
                                    context: originContext,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      // Lưu context của dialog loading
                                      loadingDialogContext = context;
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );
                                  
                                  try {
                                    // Gửi thông báo
                                    bool success = await _notificationService.sendNotification(
                                      title: _titleController.text,
                                      body: _bodyController.text,
                                      topic: 'all',
                                    );
                                    
                                    // Đóng dialog loading nếu nó vẫn hiển thị
                                    if (loadingDialogContext != null) {
                                      Navigator.of(loadingDialogContext!).pop();
                                    }
                                    
                                    // Sử dụng context gốc để hiển thị thông báo kết quả
                                    if (originContext.mounted) {
                                      ScaffoldMessenger.of(originContext).showSnackBar(
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
                                    }
                                  } catch (e) {
                                    // Đóng dialog loading nếu nó vẫn hiển thị
                                    if (loadingDialogContext != null) {
                                      Navigator.of(loadingDialogContext!).pop();
                                    }
                                    
                                    // Hiển thị lỗi
                                    if (originContext.mounted) {
                                      ScaffoldMessenger.of(originContext).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text('Gửi'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.send),
                      label: Text('Gửi thông báo khẩn cấp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
                              'Thời gian: ${_formatDate(sentAt)}',
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

  // Quản lý yêu cầu cứu trợ
    // Hiển thị danh sách yêu cầu cứu trợ
    // Cho phép phê duyệt hoặc từ chối yêu cầu
  Widget buildAdminReliefRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      //Sẽ sửa lại truy vấn khi có bảng yêu cầu cứu trợ  để tránh lỗi 
      stream: db.collection('reliefRequests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có yêu cầu cứu trợ nào'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var request = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var requestId = snapshot.data!.docs[index].id;
            String status = request['status'] ?? 'pending';
            
            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _getStatusColor(status),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.priority_high, color: _getStatusColor(status)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request['title'] ?? 'Yêu cầu cứu trợ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    Divider(height: 24),
                    Text(
                      request['description'] ?? 'Không có mô tả',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request['location'] ?? 'Không có địa điểm',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          request['userName'] ?? 'Không xác định',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Spacer(),
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          request['createdAt'] != null
                              ? _formatDate(request['createdAt'])
                              : 'Không có thời gian',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'pending')
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await db.collection('reliefRequests').doc(requestId).update({
                                  'status': 'rejected',
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã từ chối yêu cầu cứu trợ')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                            ),
                            child: Text('Từ chối'),
                          ),
                        SizedBox(width: 12),
                        if (status == 'pending')
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await db.collection('reliefRequests').doc(requestId).update({
                                  'status': 'approved',
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã phê duyệt yêu cầu cứu trợ')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Phê duyệt'),
                          ),
                        if (status != 'pending')
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await db.collection('reliefRequests').doc(requestId).update({
                                  'status': 'pending',
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã chuyển trạng thái về Đang chờ')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text('Chuyển về Đang chờ'),
                          ),
                      ],
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

  // Helper methods for admin relief request tab
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusBadge(String status) {
    String text;
    Color color;
    
    switch (status) {
      case 'approved':
        text = 'Đã phê duyệt';
        color = Colors.green;
        break;
      case 'rejected':
        text = 'Đã từ chối';
        color = Colors.red;
        break;
      default:
        text = 'Đang chờ';
        color = Colors.orange;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Trang chủ người dùng 
    // Banner người dùng 
    // Bản đồ thiên tai
    // Tin tức thời tiết
    // Yêu cầu cứu trợ gần đây đã được phê duyệt 
  Widget buildUserHomeTab() {
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
                    'Cảm ơn bạn đã sử dụng ứng dụng của chúng tôi',
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

          SizedBox(height: 30),
          
          // Bản đồ
          Text(
            'Bản đồ vùng thiên tai',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 50, color: Colors.grey[600]),
                  SizedBox(height: 10),
                  Text(
                    'Bản đồ đang được cập nhật',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),
          
          // Tin tức thời tiết
          Text(
            'Tin tức thời tiết',
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
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.cloudy_snowing, color: Colors.blue),
                  ),
                  title: Text(
                    'Dự báo thời tiết ngày ${index + 1}/5/2025',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Cảnh báo mưa lớn tại khu vực miền Trung và Tây Nguyên...',
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

          SizedBox(height: 30),
          
          // Danh sách yêu cầu cứu trợ
          Text(
            'Yêu cầu cứu trợ gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('reliefRequests')
                .where('status', isEqualTo: 'approved')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Lỗi: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Không có yêu cầu cứu trợ gần đây'),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var request = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Colors.green.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      title: Text(
                        request['title'] ?? 'Yêu cầu cứu trợ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            request['description'] ?? 'Không có mô tả',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request['location'] ?? 'Không có địa điểm',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Đã duyệt',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  // Yêu cầu cứu trợ của người dùng
    // Gửi yêu cầu cứu trợ
    // Xem yêu cầu đã gửi
  Widget buildUserReliefRequestTab() {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form gửi yêu cầu cứu trợ
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
                    'Gửi yêu cầu cứu trợ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Kiểm tra xem người dùng đã đăng nhập chưa
                  if (!isLoggedIn)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vui lòng đăng nhập',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Bạn cần đăng nhập để gửi yêu cầu cứu trợ',
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/dangnhap').then((_) {
                                fetchUserData();
                              });
                            },
                            child: Text('Đăng nhập'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Tiêu đề',
                            hintText: 'VD: Cần hỗ trợ thực phẩm',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Mô tả chi tiết',
                            hintText: 'VD: Gia đình 5 người đang thiếu thực phẩm và nước uống...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Địa điểm',
                            hintText: 'VD: Xã An Bình, Huyện Quỳnh Lưu, Nghệ An',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_titleController.text.isEmpty ||
                                  _descriptionController.text.isEmpty ||
                                  _locationController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vui lòng nhập đầy đủ thông tin'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await db.collection('reliefRequests').add({
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'location': _locationController.text,
                                  'userId': userData?['phone'], // Sử dụng phone làm userId
                                  'userName': userData?['name'] ?? 'Người dùng',
                                  'createdAt': Timestamp.now(),
                                  'status': 'pending',
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Yêu cầu cứu trợ đã được gửi thành công'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                
                                // Xóa input
                                _titleController.clear();
                                _descriptionController.clear();
                                _locationController.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.send),
                            label: Text('Gửi yêu cầu'),
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
                ],
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          // Yêu cầu của tôi
          Text(
            'Yêu cầu của tôi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          
          if (!isLoggedIn)
            Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Đăng nhập để xem các yêu cầu của bạn'),
                ),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: db.collection('reliefRequests')
                  .where('userId', isEqualTo: userData?['phone'])
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}');
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Bạn chưa gửi yêu cầu cứu trợ nào'),
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var request = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    var requestId = snapshot.data!.docs[index].id;
                    String status = request['status'] ?? 'pending';
                    
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _getStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    request['title'] ?? 'Yêu cầu cứu trợ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(status),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(request['description'] ?? 'Không có mô tả'),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    request['location'] ?? 'Không có địa điểm',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Ngày tạo: ${_formatDate(request['createdAt'])}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (status == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await db.collection('reliefRequests').doc(requestId).delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã xóa yêu cầu cứu trợ'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text('Xóa yêu cầu'),
                                  ),
                                ],
                              ),
                          ],
                        ),
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

  // Tab cài đặt người dùng (thông tin tài khoản)
  // Thông tin cá nhân
  // Đổi mật khẩu
  Widget buildUserSettingsTab() {
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
                      Navigator.pushNamed(context, '/dangnhap').then((_) {
                        fetchUserData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                if (userData?.containsKey('isAdmin') == true && userData?['isAdmin'] == true)
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
                        buildInfoItem(
                          icon: Icons.phone,
                          title: 'Số điện thoại',
                          value: userData?['phone'] ?? 'Không có',
                        ),
                        
                        // Ngày tạo tài khoản
                        buildInfoItem(
                          icon: Icons.calendar_today,
                          title: 'Ngày tạo tài khoản',
                          value: userData?['created_at'] != null
                            ? _formatDate(userData?['created_at'])
                            : 'Không có thông tin',
                        ),
                        
                        // Trạng thái
                        buildInfoItem(
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
                      buildOptionItem(
                        icon: Icons.security,
                        title: 'Đổi mật khẩu',
                        onTap: () {
                          // Xử lý đổi mật khẩu
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Thông báo'),
                              content: Text('Tính năng đổi mật khẩu sẽ sớm được cập nhật!'),
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
                      buildOptionItem(
                        icon: Icons.edit,
                        title: 'Chỉnh sửa thông tin',
                        onTap: () {
                          // Xử lý chỉnh sửa thông tin
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Thông báo'),
                              content: Text('Tính năng chỉnh sửa thông tin sẽ sớm được cập nhật!'),
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
                      buildOptionItem(
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Đăng xuất'),
                                content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
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
                ),
              ],
            ),
        ],
      ),
    );
  }
}
