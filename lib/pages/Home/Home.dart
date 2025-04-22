import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tabs/admin/admin_users_tab.dart';
import 'tabs/admin/admin_notifications_tab.dart';
import 'tabs/admin/admin_relief_requests_tab.dart';
import 'tabs/user/user_home_tab.dart';
import 'tabs/user/user_relief_request_tab.dart';
import 'tabs/user/user_settings_tab.dart';


// Cấu trúc dữ liệu 
// users: Thông tin người dùng (name, phone, password, isAdmin, isLoggedIn)
// tblYeuCau gồm có tiêu đề, mô tả, vị trí, trạng thái, mức độ, userId, thời gian tạo
// notifications: Thông báo đã gửi


//Khai báo một StatefulWidget cho trang Home
class Home extends StatefulWidget {
  final bool isAdmin;
  // Constructor cho Home, có thể nhận tham số isAdmin
  // để xác định xem người dùng có phải là admin hay không
  const Home({Key? key, this.isAdmin = false}) : super(key: key); 
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

  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  // Thêm các controller vào đây - là thuộc tính của lớp
  // late TextEditingController _titleController;
  // late TextEditingController _bodyController;
  // final NotificationService _notificationService = NotificationService();

  @override
  void initState() { //Widget khởi tạo lần đầu tiên 
    super.initState();
    fetchUserData();
    
    // // Khởi tạo các controller
    // _titleController = TextEditingController();
    // _bodyController = TextEditingController();
  }
  
  // @override
  // void dispose() {
  //   // Giải phóng các controller khi widget bị hủy
  //   _titleController.dispose();
  //   _bodyController.dispose();
  //   super.dispose();
  // }

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
       debugPrint('Lỗi khi lấy thông tin người dùng: $e');
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
       debugPrint('Lỗi khi đăng xuất: $e');
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
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text('Đăng xuất'),
                      content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
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
                // buildAdminUsersManagementTab(),
                // buildAdminNotificationsTab(),
                // buildAdminReliefRequestsTab(),
                AdminUsersTab(userData: userData, isLoggedIn: isLoggedIn),
                AdminNotificationsTab(
                    userData: userData, isLoggedIn: isLoggedIn),
                AdminReliefRequestsTab(
                    userData: userData, isLoggedIn: isLoggedIn),
              ]
            : [
                // Các tab cho người dùng thường
                // buildUserHomeTab(),
                // buildUserReliefRequestTab(),
                // buildUserSettingsTab(),
                UserHomeTab(userData: userData, isLoggedIn: isLoggedIn),
                UserReliefRequestTab(
                    userData: userData, isLoggedIn: isLoggedIn),
                UserSettingsTab(
                    userData: userData,
                    isLoggedIn: isLoggedIn,
                    onLogout: logout),
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

}
