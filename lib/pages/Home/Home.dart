import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class Home extends StatefulWidget {
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
        title: Text('Trang chủ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Hiển thị nút đăng nhập hoặc đăng xuất tùy thuộc vào trạng thái
          IconButton(
            icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
            onPressed: () {
              if (isLoggedIn) {
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
                            Navigator.of(context).pop(); // Đóng hộp thoại
                          },
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Đóng hộp thoại
                            await logout(); // Đăng xuất
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
                  // Cập nhật lại dữ liệu người dùng sau khi quay lại từ màn hình đăng nhập
                  fetchUserData();
                });
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Trang chủ - luôn hiển thị, không phụ thuộc vào đăng nhập
          buildHomeTab(),
          // Trang tài khoản - có thể tùy chỉnh để hiển thị khác nhau khi đã đăng nhập hoặc chưa
          buildProfileTab(),
          // Trang cài đặt
          buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Xử lý khi nhấn nút SOS
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
    return Center(
      child: Text('Trang cài đặt sẽ hiển thị ở đây'),
    );
  }
}
