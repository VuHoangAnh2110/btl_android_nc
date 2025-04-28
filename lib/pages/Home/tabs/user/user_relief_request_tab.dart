import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../widgets/common/status_badge.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class UserReliefRequestTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const UserReliefRequestTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _UserReliefRequestTabState createState() => _UserReliefRequestTabState();
}

class _UserReliefRequestTabState extends State<UserReliefRequestTab> {
  // Khởi tạo 3 controller để quản lý input:
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  // Đối tượng Dio để tải ảnh
  final Dio _dio = Dio();
  // Khởi tạo kết nối Firestore để làm việc với dữ liệu:
  final FirebaseFirestore db = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  // Biến để lưu ảnh đã chọn
  File? _selectedImage;
  String? _imageUrl;
  // Biến để hiển thị trạng thái đang tải
  bool _isLoading = false;
  // Biến để lưu vị trí đã chọn
  Position? _currentPosition;
  String? _currentAddress;

  // Giải phóng tài nguyên khi widget bị hủy. Tránh memory leak cho các controller.
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  // Hiển thị dialog chọn nguồn ảnh
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn ảnh từ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Thư viện ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Máy ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tải ảnh lên dịch vụ ImgBB thay vì Firebase Storage
  Future<String?> _uploadImageToImgBB() async {
    if (_selectedImage == null) return null;
    
    try {
      // Chuẩn bị FormData để tải lên
      FormData formData = FormData.fromMap({
        'key': 'c0b40e22c1f72d0e95a4b227825a961b', // API key của ImgBB (nên đặt vào biến môi trường)
        'image': await MultipartFile.fromFile(_selectedImage!.path),
      });
      
      // Gọi API của ImgBB
      final response = await _dio.post(
        'https://api.imgbb.com/1/upload',
        data: formData,
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Trả về URL của ảnh đã tải lên
        return response.data['data']['url'];
      } else {
        print('Lỗi khi tải ảnh lên ImgBB: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi tải ảnh: $e');
      return null;
    }
  }

  // Hàm kiểm tra quyền truy cập vị trí
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng bật dịch vụ vị trí trên thiết bị')),
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
        SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn')),
      );
      return false;
    }
    
    return true;
  }

  // Hàm lấy vị trí hiện tại
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      _getAddressFromLatLng();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm chuyển đổi tọa độ thành địa chỉ
  Future<void> _getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = 
            '${place.street}, '
            '${place.subAdministrativeArea}, ${place.administrativeArea}';
          _locationController.text = _currentAddress!;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy địa chỉ: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xây dựng giao diện.
  @override
  Widget build(BuildContext context) {
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
                  if (!widget.isLoggedIn)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(52),
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
                              Navigator.pushNamed(context, '/dangnhap');
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
                            hintText:
                                'VD: Gia đình 5 người đang thiếu thực phẩm và nước uống...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 15),
                        Stack(
                          children: [
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Địa điểm',
                                hintText:
                                    'VD: Xã An Bình, Huyện Quỳnh Lưu, Nghệ An',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.location_on),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.my_location),
                                  onPressed: _getCurrentLocation,
                                  tooltip: 'Lấy vị trí hiện tại',
                                ),
                              ),
                            ),
                            if (_isLoading)
                              Positioned(
                                right: 10,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm hình ảnh (tùy chọn)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _selectedImage == null
                                  ? Center(
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: _showImageSourceDialog,
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        Center(
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              padding: EdgeInsets.all(5),
                                              constraints: BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedImage = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        //Nút gửi yêu cầu cứu trợ
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_titleController.text.isEmpty ||
                                  _descriptionController.text.isEmpty ||
                                  _locationController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Vui lòng nhập đầy đủ thông tin'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                // Tải ảnh lên ImgBB (nếu có)
                                // String? imageUrl;
                                if (_selectedImage != null) {
                                  _imageUrl = await _uploadImageToImgBB();
                                }

                                // Tạo dữ liệu cho yêu cầu cứu trợ
                                Map<String, dynamic> requestData = {
                                  'sTieuDe': _titleController.text,
                                  'sMoTa': _descriptionController.text,
                                  'sViTri': _locationController.text,
                                  'userId': widget.userData?['phone'],
                                  'userName': widget.userData?['name'] ?? 'Người dùng',
                                  'tNgayGui': Timestamp.now(),
                                  'sTrangThai': 'chờ duyệt',
                                  'sMucDo': 'Thường',
                                };

                                // Thêm tọa độ vị trí nếu có
                                if (_currentPosition != null) {
                                  requestData['sToaDo'] = GeoPoint(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  );
                                }

                                // Thêm URL ảnh nếu có
                                if (_imageUrl != null) {
                                  requestData['sHinhAnh'] = _imageUrl;
                                }

                                // Lưu vào Firestore
                                await db.collection('tblYeuCau').add(requestData);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Yêu cầu cứu trợ đã được gửi thành công'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // reset form gửi yêu cầu
                                _titleController.clear();
                                _descriptionController.clear();
                                _locationController.clear();
                                setState(() {
                                  _selectedImage = null;
                                  _currentPosition = null;
                                  _currentAddress = null;
                                  _isLoading = false;
                                });
                              } catch (e) {
                                setState(() {
                                  _isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: _isLoading 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.send),
                            label: Text(_isLoading ? 'Đang gửi...' : 'Gửi yêu cầu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.6),
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

          // Danh sách yêu cầu của tài khoản
          Text(
            'Yêu cầu của tôi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          if (!widget.isLoggedIn)
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
              stream: db
                  .collection('tblYeuCau')
                  .where('userId', isEqualTo: widget.userData?['phone'])
                  .orderBy('tNgayGui', descending: true)
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
                    var request = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    var requestId = snapshot.data!.docs[index].id;
                    String status = request['sTrangThai'] ?? 'chờ duyệt';

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị ảnh nếu có
                          if (request.containsKey('sHinhAnh') && request['sHinhAnh'] != null)
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(9),
                                  topRight: Radius.circular(9),
                                ),
                                child: Image.network(
                                  request['sHinhAnh'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request['sTieuDe'] ?? 'Yêu cầu cứu trợ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(status: status),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text(request['sMoTa'] ?? 'Không có mô tả'),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        request['sViTri'] ?? 'Không có địa điểm',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Ngày tạo: ${DateFormatter.formatDate(request['tNgayGui'])}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if (status == 'chờ duyệt')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await db
                                                .collection('tblYeuCau')
                                                .doc(requestId)
                                                .delete();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Đã xóa yêu cầu cứu trợ'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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
                                        child: Text('Hủy yêu cầu'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'chấp nhận':
        return Colors.green;
      case 'từ chối':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  
}
