import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import
import 'tabs/admin/admin_users_tab.dart';
import 'tabs/admin/admin_notifications_tab.dart';
import 'tabs/admin/admin_relief_requests_tab.dart';
import 'tabs/admin/admin_evacuation_areas_tab.dart'; // Thêm dòng này
import 'tabs/user/user_home_tab.dart';
import 'tabs/user/user_relief_request_tab.dart';
import 'tabs/user/user_settings_tab.dart';
import '../EvacuationArea/evacuation_areas_list_user.dart';
import 'package:btl_android_nc/services/notification_service.dart';  // Thêm import này
import '../../widgets/PolicyAgreementDialog.dart';

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
  bool _isAdmin = false; // Mặc định là false, cần cập nhật dựa trên hệ thống xác thực

  final FirebaseFirestore db = FirebaseFirestore.instance;
  // Biến để lưu vị trí đã chọn
  Position? _toaDoHienTai;
  String? _diaChiHienTai;

  @override
  void initState() { //Widget khởi tạo lần đầu tiên 
    super.initState();
    fetchUserData();
    _checkAdminStatus();
    // Hiển thị dialog chính sách sau khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PolicyAgreementDialog.showIfNeeded(context, _isAdmin);
    });
  }

  Future<void> fetchUserData() async {
    try {
      // Lấy thông tin đăng nhập từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        // Đọc thông tin admin từ SharedPreferences
        final bool savedIsAdmin = prefs.getBool('isAdmin') ?? false;
        final String userName = prefs.getString('userName') ?? '';
        final String userPhone = prefs.getString('userPhone') ?? '';
        
        // Đã có người dùng đăng nhập, truy vấn Firestore để lấy dữ liệu mới nhất
        final userDoc = await db.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          Map<String, dynamic> firestoreUserData = userDoc.data() as Map<String, dynamic>;
          
          // Kiểm tra quyền admin từ Firestore 
          // Cập nhật lại nếu có thay đổi
          bool isAdmin = firestoreUserData['isAdmin'] == true;
          
          // Chỉ cập nhật SharedPreferences nếu trạng thái admin thay đổi
          if (savedIsAdmin != isAdmin) {
            await prefs.setBool('isAdmin', isAdmin);
          }
          
          // Tạo object userData với đầy đủ thông tin
          Map<String, dynamic> updatedUserData = {
            ...firestoreUserData,
            'id': userId,
            'isAdmin': isAdmin
          };
          
          setState(() {
            userData = updatedUserData;
            isLoggedIn = true;
            isActuallyAdmin = isAdmin;
          });
        } else {
          // Tài khoản đã bị xóa khỏi Firestore, đăng xuất
          logout();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tài khoản không tồn tại, vui lòng đăng nhập lại'))
          );
        }
      } else {
        setState(() {
          userData = null;
          isLoggedIn = false;
          isActuallyAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin người dùng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xác thực: $e'))
      );
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
      
      // Reset trạng thái local và đặt lại chỉ số tab
      setState(() {
        userData = null;
        isLoggedIn = false;
        isActuallyAdmin = false;
        _selectedIndex = 0; // Đặt lại chỉ số tab về 0
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

  Future<void> _checkAdminStatus() async {
    // Thêm logic kiểm tra người dùng có quyền admin không
    // Ví dụ: Nếu sử dụng Firebase Auth và Firestore
    try {
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   final userData = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user.uid)
      //     .get();
      //   setState(() {
      //     _isAdmin = userData.data()?['role'] == 'admin';
      //   });
      // }
      
      // TẠM THỜI: Để false để dialog luôn hiển thị
      setState(() {
        _isAdmin = false;
      });
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái admin: $e');
    }
  }

  // Giao diện 
  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị giao diện admin khi người dùng đã đăng nhập và có quyền admin
    bool showAdminInterface = isLoggedIn && isActuallyAdmin;
    
    return Scaffold( // Scaffold là widget chính của trang
      appBar: AppBar(
        title: Text(showAdminInterface ? 'Trang quản trị' : 'Trang chủ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Thêm nút chính sách ở đây
          IconButton(
            icon: Icon(Icons.policy),
            tooltip: 'Chính sách sử dụng',
            onPressed: () {
              // Hiển thị dialog chính sách - bỏ qua kiểm tra đã đồng ý hay chưa
              PolicyAgreementDialog.show(context);
            },
          ),
          
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
                AdminEvacuationAreasTab(userData: userData, isLoggedIn: isLoggedIn), // Thêm tab mới
              ]
            : [
                // Các tab cho người dùng thường
                UserHomeTab(userData: userData, isLoggedIn: isLoggedIn),
                UserReliefRequestTab(userData: userData, isLoggedIn: isLoggedIn),
                EvacuationAreasListUser(),
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
                  label: 'Yêu Cầu Cứu trợ',
                ),
                BottomNavigationBarItem( // Thêm item mới
                  icon: Icon(Icons.location_on),
                  label: 'Khu vực di tản',
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
                  icon: Icon(Icons.location_on),
                  label: 'Khu vực di tản',
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
        type: BottomNavigationBarType.fixed, // Thêm dòng này để hiển thị tất cả các tab
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
                  // Controller cho ô nhập số điện thoại
                  TextEditingController phoneController = TextEditingController();
                  
                  // Tự động điền số điện thoại của người dùng nếu có
                  if (userData != null && userData!['phone'] != null) {
                    phoneController.text = userData!['phone'];
                  }
                  
                  return AlertDialog(
                    title: Text('Gửi SOS'),
                    content: SingleChildScrollView( // Thêm SingleChildScrollView để ngăn tràn
                      child: Container(
                        width: double.maxFinite, // Đảm bảo chiều rộng đầy đủ
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Giữ kích thước nhỏ nhất có thể
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bạn chắc chắn muốn gửi yêu cầu SOS!'),
                            SizedBox(height: 10),
                            Text('Vị trí của bạn:'),
                            Text(
                              _diaChiHienTai ?? 'Chưa xác định được địa chỉ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 3, // Giới hạn số dòng hiển thị
                              overflow: TextOverflow.ellipsis, // Hiển thị dấu ... nếu quá dài
                            ),
                            SizedBox(height: 16),
                            Text('Số điện thoại liên hệ:'),
                            SizedBox(height: 8), // Khoảng cách trước TextField
                            TextField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                hintText: 'Nhập số điện thoại để liên hệ',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                isDense: true, // Làm cho TextField nhỏ gọn hơn
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Lưu context gốc để sử dụng sau này
                          final originContext = context;
                          
                          // Lấy số điện thoại từ input
                          final contactPhone = phoneController.text.trim();
                          
                          // Đóng dialog xác nhận
                          Navigator.of(context).pop();
                          
                          // Lưu tham chiếu để kiểm tra nếu widget vẫn được mounted
                          bool isMounted = true;
                          
                          // Tạo BuildContext cho dialog loading
                          BuildContext? dialogContext;
                          
                          // Hiển thị dialog loading
                          if (isMounted) {
                            showDialog(
                              context: originContext,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                dialogContext = context;
                                return const Center(child: CircularProgressIndicator());
                              },
                            );
                          }
                          
                          try {
                            // Chuẩn bị dữ liệu yêu cầu SOS
                            Map<String, dynamic> requestData = {
                              'sTieuDe': "Khẩn cấp",
                              'sMoTa': "Yêu cầu cứu trợ khẩn cấp. Chú ý.",
                              'sViTri': _diaChiHienTai ?? 'Chưa xác định được địa chỉ',
                              'userId': userData?['phone'] ?? contactPhone,
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
                            
                            // Lưu yêu cầu SOS vào Firestore
                            DocumentReference docRef = await FirebaseFirestore.instance
                                .collection('tblYeuCau')
                                .add(requestData);
                            
                            // Lấy ID của yêu cầu SOS vừa tạo
                            String requestId = docRef.id;
                            
                            // Chuẩn bị dữ liệu bổ sung cho thông báo
                            Map<String, dynamic> additionalData = {
                              'type': 'sos',
                              'requestId': requestId,
                              'location': _diaChiHienTai ?? 'Không xác định',
                              'coordinates': _toaDoHienTai != null 
                                  ? '${_toaDoHienTai!.latitude},${_toaDoHienTai!.longitude}' 
                                  : 'Không có',
                              'userName': userData?['name'] ?? 'Người dùng',
                              'userPhone': userData?['phone'] ?? 'Không có SĐT',
                              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                            };
                            
                            // Sử dụng NotificationService để gửi thông báo
                            final notificationService = NotificationService();
                            
                            // Gửi thông báo tới admin
                            bool sent = await notificationService.sendNotification(
                              title: 'SOS - Yêu cầu cứu trợ khẩn cấp',
                              body: 'Từ ${userData?['name'] ?? 'Người dùng'}: ${_diaChiHienTai ?? 'Vị trí chưa xác định'}',
                              topic: 'admin',  
                              data: additionalData,
                            );
                            
                            // Đóng dialog loading an toàn sử dụng dialogContext
                            if (dialogContext != null) {
                              Navigator.of(dialogContext!).pop();
                              dialogContext = null; // Xóa tham chiếu
                            }
                            
                            // Kiểm tra nếu context còn hợp lệ trước khi hiển thị SnackBar
                            if (mounted) {
                              // Sử dụng WidgetsBinding để đảm bảo hiển thị SnackBar sau khi navigate xong
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  if (sent) {
                                    ScaffoldMessenger.of(originContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Gửi tín hiệu SOS thành công! Thông báo đã được gửi đến quản trị viên.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(originContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã lưu yêu cầu SOS, nhưng có thể có vấn đề khi gửi thông báo đến quản trị viên.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              });
                            }
                          } catch (e) {
                            // Đóng dialog loading an toàn
                            if (dialogContext != null) {
                              Navigator.of(dialogContext!).pop();
                              dialogContext = null; // Xóa tham chiếu
                            }
                            
                            // Hiển thị lỗi nếu widget vẫn tồn tại
                            if (mounted) {
                              // Sử dụng WidgetsBinding để đảm bảo hiển thị SnackBar sau khi navigate xong
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(originContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Gửi SOS lỗi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              });
                            }
                          }
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
