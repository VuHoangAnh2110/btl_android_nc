import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import
import 'tabs/admin/admin_users_tab.dart';
import 'tabs/admin/admin_notifications_tab.dart';
import 'tabs/admin/admin_relief_requests_tab.dart';
import 'tabs/user/user_home_tab.dart';
import 'tabs/user/user_relief_request_tab.dart';
import 'tabs/user/user_settings_tab.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  // Biến để lưu vị trí đã chọn
  Position? _toaDoHienTai;
  String? _diaChiHienTai;

  @override
  void initState() { //Widget khởi tạo lần đầu tiên 
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      // Lấy thông tin đăng nhập từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        // Đã có người dùng đăng nhập, lấy thông tin chi tiết từ Firestore
        final userDoc = await db.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> firestoreUserData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            userData = firestoreUserData;
            isLoggedIn = true;
            isActuallyAdmin = prefs.getBool('isAdmin') ?? false;
          });
        } else {
          // Tài khoản không còn tồn tại trong Firestore
          logout(); // Đăng xuất nếu tài khoản không còn tồn tại
        }
      } else {
        // Không có người dùng đăng nhập
        setState(() {
          userData = null;
          isLoggedIn = false;
          isActuallyAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin người dùng: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Xóa dữ liệu đăng nhập từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('isAdmin');
      await prefs.remove('userName');
      await prefs.remove('userPhone');
      
      // Reset trạng thái local
      setState(() {
        userData = null;
        isLoggedIn = false;
        isActuallyAdmin = false;
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

  // Hàm kiểm tra quyền truy cập vị trí
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Hiển thị thông báo yêu cầu bật dịch vụ định vị
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Định vị bị tắt'),
            content: Text('Vui lòng bật dịch vụ định vị để gửi SOS'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openLocationSettings();
                },
                child: Text('Mở cài đặt'),
              ),
            ],
          );
        },
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return false;
    }
    
    return true;
  }

  // Hàm lấy vị trí hiện tại
  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _toaDoHienTai = position;
      });
  
      _getAddressFromLatLng();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
      );
    }
  }

  // Hàm chuyển đổi tọa độ thành địa chỉ
  Future<void> _getAddressFromLatLng() async {
    try {
      if (_toaDoHienTai == null) return;
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _toaDoHienTai!.latitude,
        _toaDoHienTai!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _diaChiHienTai = '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy địa chỉ: $e')),
      );
    }
  }

  // Giao diện 
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
                UserHomeTab(userData: userData, isLoggedIn: isLoggedIn),
                AdminUsersTab(userData: userData, isLoggedIn: isLoggedIn),
                AdminNotificationsTab(userData: userData, isLoggedIn: isLoggedIn),
                AdminReliefRequestsTab(userData: userData, isLoggedIn: isLoggedIn),
              ]
            : [
                // Các tab cho người dùng thường
                UserHomeTab(userData: userData, isLoggedIn: isLoggedIn),
                UserReliefRequestTab(userData: userData, isLoggedIn: isLoggedIn),
                UserSettingsTab(
                    userData: userData,
                    isLoggedIn: isLoggedIn,
                    onLogout: logout),
              ],
      ),
      
      // Bottom navigation với các mục khác nhau cho admin và người dùng thường
      bottomNavigationBar: BottomNavigationBar( // Thanh điều hướng dưới cùng 
        items: showAdminInterface
            ? [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Người dùng',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_active),
                  label: 'Thông báo khẩn',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.volunteer_activism),
                  label: 'Cứu trợ',
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
        onPressed: () async{
          // Hiển thị đang tải
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try{
            await _getCurrentLocation();
            if (_toaDoHienTai == null && _diaChiHienTai == null) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Không thể lấy vị trí, tọa độ hiện tại')),
              );
            } else {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Gửi SOS'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bạn chắc chắn muốn gửi yêu cầu SOS!'),
                        SizedBox(height: 10),
                        Text('Vị trí của bạn:'),
                        Text(_diaChiHienTai ?? 'Chưa xác định được địa chỉ'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                            Map<String, dynamic> requestData = {
                            'sTieuDe': "Khẩn cấp",
                            'sMoTa': "Yêu cầu cứu trợ khẩn cấp. Chú ý.",
                            'sViTri': _diaChiHienTai ?? 'Chưa xác định được địa chỉ',
                            'userId': userData?['phone'] ?? 'Trống',
                            'userName': userData?['name'] ?? 'Người dùng',
                            'tNgayGui': Timestamp.now(),
                            'sTrangThai': 'chờ duyệt',
                            'sMucDo': 'Khẩn cấp',
                          };
                          if (_toaDoHienTai != null) {
                            requestData['sToaDo'] = GeoPoint(
                              _toaDoHienTai!.latitude,
                              _toaDoHienTai!.longitude,
                            );
                          }
                          await FirebaseFirestore.instance.collection('tblYeuCau').add(requestData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gửi tín hiệu SOS thành công!')),
                          );
                        },
                        child: Text('Gửi SOS'),
                      ),
                    ],
                  );
                },
              );
            }
          } catch (e) {
            // Đóng dialog đang tải
            Navigator.of(context).pop();
            // Hiển thị thông báo lỗi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gửi SOS lỗi: $e')),
            );
          }
        },
        label: Text('SOS'),
        icon: Icon(Icons.warning, color: Colors.white),
        backgroundColor: Colors.red,
      ),
    );
  }

}
