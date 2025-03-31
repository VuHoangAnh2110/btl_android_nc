import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Thông tin người dùng hiện tại
  Map<String, dynamic>? userData;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
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
                          Navigator.of(context).pop(); // Đóng hộp thoại
                        },
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Đóng hộp thoại
                          // Quay lại màn hình đăng nhập
                          Navigator.pushReplacementNamed(context, '/dangnhap');
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Trang chủ
          buildHomeTab(),
          // Trang tài khoản
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
                  'Chào mừng bạn đã đăng nhập thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Cùng nhau hỗ trợ người dân vùng thiên tai',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Các tính năng chính
          Text(
            'Tính năng chính',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),

          // Grid các tính năng
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
    return Center(
      child: Text('Trang thông tin tài khoản sẽ hiển thị ở đây'),
    );
  }

  // Widget cho tab Cài đặt
  Widget buildSettingsTab() {
    return Center(
      child: Text('Trang cài đặt sẽ hiển thị ở đây'),
    );
  }
}
