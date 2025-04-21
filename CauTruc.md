
1. Cấu trúc cơ bản của ứng dụng
StatefulWidget và StatelessWidget
```dart
// StatefulWidget - khi cần quản lý trạng thái
class Home extends StatefulWidget {
  final bool isAdmin;
  Home({this.isAdmin = false});
  
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Các biến trạng thái
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    // UI logic
  }
}

// StatelessWidget - khi không cần quản lý trạng thái
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  
  InfoCard({required this.title, required this.content});
  
  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}
```
Vòng đời Widget 
```dart
@override
void initState() {  // Khởi tạo khi widget được tạo lần đầu
  super.initState();
  fetchUserData();
}

@override
void dispose() {  // Dọn dẹp khi widget bị hủy
  _controller.dispose();
  super.dispose();
}
```
2. Quản lý trạng thái
setState
```dart 
setState(() {
  _selectedIndex = index;
  isLoggedIn = true;
});
``` 
Cập nhật UI từ dữ liệu bất đồng bộ 
```dart 
Future<void> fetchUserData() async {
  try {
    // Gọi API
    final querySnapshot = await db.collection('users').get();
    
    setState(() {
      // Cập nhật UI
      if (loggedInUser != null) {
        userData = loggedInUser.data() as Map<String, dynamic>;
        isLoggedIn = true;
        isActuallyAdmin = userData!.containsKey('isAdmin') && userData!['isAdmin'] == true;
      }
    });
  } catch (e) {
    print('Lỗi: $e');
  }
}
```
3. Điều hướng
Điều hướng cơ bản
```dart
// Chuyển sang màn hình mới
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SecondScreen()),
);

// Thay thế màn hình hiện tại
Navigator.pushReplacement(
  context, 
  MaterialPageRoute(builder: (context) => Home(isAdmin: isAdmin))
);

// Chuyển đến route với tên
Navigator.pushNamed(context, '/dangnhap');

// Quay lại màn hình trước
Navigator.pop(context);

// Xử lý kết quả từ màn hình trước khi quay lại
Navigator.pushNamed(context, '/dangnhap').then((_) {
  fetchUserData(); // Cập nhật dữ liệu
});
```
Hộp thoại (Dialog)
```dart
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
```
4. Cấu trúc layout cơ bản
Scaffold
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Tiêu đề'),
    actions: [IconButton(...)],
  ),
  body: Container(...),
  bottomNavigationBar: BottomNavigationBar(...),
  floatingActionButton: FloatingActionButton(...),
);
```
Các Layout chính
```dart
// Column: xếp các widget theo chiều dọc
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Tiêu đề'),
    SizedBox(height: 10),
    TextField(...),
  ],
);

// Row: xếp các widget theo chiều ngang
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Icon(Icons.person),
    Text('Tên người dùng'),
    Spacer(),
    Icon(Icons.edit),
  ],
);

// Stack: xếp chồng các widget
Stack(
  children: [
    Image.network('url_background'),
    Positioned(
      bottom: 10,
      right: 10,
      child: Icon(Icons.favorite),
    ),
  ],
);

// IndexedStack: hiển thị 1 trong nhiều widget nhưng giữ trạng thái của tất cả
IndexedStack(
  index: _selectedIndex,
  children: [
    FirstTab(),
    SecondTab(),
    ThirdTab(),
  ],
);
``` 
Container và Card
```dart
 Container(
  width: double.infinity,
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Column(...),
);

Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Colors.green, width: 1),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(...),
  ),
);
```
5. Kết nối dữ liệu Firebase
Thiết lập Firebase
```dart
 // Import package
import 'package:cloud_firestore/cloud_firestore.dart';

// Khởi tạo instance
final FirebaseFirestore db = FirebaseFirestore.instance;
```
Truy vấn dữ liệu
```dart 
// Lấy tất cả document từ collection
final querySnapshot = await db.collection('users').get();

// Truy vấn có điều kiện
final userQuery = await db
    .collection('users')
    .where('phone', isEqualTo: phoneNumber)
    .where('password', isEqualTo: password)
    .get();

// Sắp xếp kết quả
db.collection('reliefRequests')
    .orderBy('createdAt', descending: true)
    .get();

// Giới hạn số lượng kết quả
db.collection('reliefRequests')
    .limit(5)
    .get();
```
StreamBuilder với Firestore
```dart 
StreamBuilder<QuerySnapshot>(
  stream: db.collection('users').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Text('Lỗi: ${snapshot.error}');
    }
    
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text('Không có dữ liệu');
    }
    
    return ListView.builder(
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
        var docId = snapshot.data!.docs[index].id;
        // Hiển thị dữ liệu
      },
    );
  },
);
```
Thêm/cập nhật dữ liệu
```dart
// Thêm document mới
await db.collection('reliefRequests').add({
  'title': title,
  'description': description,
  'userId': userId,
  'createdAt': Timestamp.now(),
});

// Cập nhật document
await db.collection('users').doc(userId).update({
  'isLoggedIn': true
});

// Xóa document
await db.collection('users').doc(userId).delete(); 
```
6. Xử lý form
TextFormField và validation
```dart
TextFormField(
  controller: _emailController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!value.contains('@')) {
      return 'Email không hợp lệ';
    }
    return null;
  },
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Nhập email của bạn',
    prefixIcon: Icon(Icons.email),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
); 
```
Form và FormKey 
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(...),
      TextFormField(...),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Xử lý submit form
          }
        },
        child: Text('Đăng nhập'),
      ),
    ],
  ),
);
```
7. UI Components tiện dụng
AppBar
```dart 
AppBar(
  title: Text('Trang chủ'),
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: Icon(Icons.logout),
      onPressed: () { /* Xử lý */ },
    ),
  ],
);
```
BottomNavigationBar 
```dart 
BottomNavigationBar(
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
);
```

FloatingActionButton
```dart 
FloatingActionButton.extended(
  onPressed: () {
    // Xử lý khi nhấn
  },
  label: Text('SOS'),
  icon: Icon(Icons.warning),
  backgroundColor: Colors.red,
);
```
ListView và GridView 
```dart 
// ListView cơ bản
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].title),
      subtitle: Text(items[index].description),
    );
  },
);

// ListView trong SingleChildScrollView
SingleChildScrollView(
  child: Column(
    children: [
      // Các widget khác
      ListView.builder(
        shrinkWrap: true, // Quan trọng!
        physics: NeverScrollableScrollPhysics(), // Tránh xung đột scroll
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(...);
        },
      ),
    ],
  ),
);

// GridView
GridView.count(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  childAspectRatio: 1.2,
  crossAxisSpacing: 15,
  mainAxisSpacing: 15,
  children: [
    buildFeatureCard(...),
    buildFeatureCard(...),
    // Các card khác
  ],
);
```
8. Phương pháp phân quyền 
```dart 
// 1. Truyền quyền qua constructor
Home({this.isAdmin = false});

// 2. Kiểm tra quyền trong Firebase
isActuallyAdmin = userData!.containsKey('isAdmin') && userData!['isAdmin'] == true;

// 3. Quyết định hiển thị UI dựa trên quyền
bool showAdminInterface = widget.isAdmin || isActuallyAdmin;

// 4. Hiển thị UI tương ứng
body: IndexedStack(
  index: _selectedIndex,
  children: showAdminInterface 
      ? [
          buildAdminTab1(),
          buildAdminTab2(),
        ]
      : [
          buildUserTab1(),
          buildUserTab2(),
        ],
),
```
9. Hiển thị thông báo 
Snackbar 
```dart 
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Đăng nhập thành công'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
    action: SnackBarAction(
      label: 'Đóng',
      onPressed: () {
        // Xử lý khi người dùng nhấn nút Đóng
      },
    ),
  ),
);
```
Loading Dialog
```dart 
// Hiển thị dialog loading
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Center(
    child: CircularProgressIndicator(),
  ),
);

// Đóng dialog
Navigator.pop(context);
```
10. Extract widgets cho tái sử dụng 
```dart 
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
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
``` 