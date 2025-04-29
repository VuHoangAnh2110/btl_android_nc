import 'package:btl_android_nc/pages/chi_tiet_yeu_cau_screen.dart';
import 'package:btl_android_nc/pages/xem_tat_ca_yeu_cau.dart'; // Thêm import mới
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/common/feature_card.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/news_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../pages/news_detail_screen.dart';
import '../../../../pages/chi_tiet_yeu_cau_screen.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class UserHomeTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const UserHomeTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab> {
  Position? _currentPosition;
  late WebViewController _webViewController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(52),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isLoggedIn
                      ? 'Chào mừng, ${widget.userData?['name'] ?? 'Người dùng'}!'
                      : 'Chào mừng đến với ứng dụng Hỗ Trợ Thiên Tai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10),
                if (widget.isLoggedIn)
                  Text(
                    'Số điện thoại: ${widget.userData?['phone'] ?? 'Không có'}',
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

          Text(
            'Tin tức thời tiết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildNewsSection(),

          SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yêu cầu cứu trợ gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => XemTatCaYeuCau(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 15),
          _buildRecentReliefsSection(),

          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: NewsService.fetchWeatherNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text('Không thể tải tin tức: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final newsList = snapshot.data ?? [];

        if (newsList.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Không có tin tức nào')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: newsList.length > 5 ? 5 : newsList.length,
          itemBuilder: (context, index) {
            final item = newsList[index];
            final String imageUrl = item['imageUrl'] ?? '';

            return Card(
              margin: EdgeInsets.only(bottom: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                              Icons.cloudy_snowing,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : Icon(Icons.cloudy_snowing, color: Colors.blue),
                ),
                title: Text(
                  item['title'] ?? 'Không có tiêu đề',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đăng: ${_formatNewsDate(item['pubDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(
                        title: item['title'] ?? 'Không có tiêu đề',
                        link: item['link'] ?? '',
                        description: item['description'] ?? '',
                        imageUrl: item['imageUrl'],
                        pubDate: item['pubDate'],
                      ),
                    ),
                  );
                },
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentReliefsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('tblYeuCau')
        .where('sTrangThai', whereIn: ['đang xác minh', 'chấp nhận']) // Chỉ lấy yêu cầu đang xác minh và chấp nhận
        .limit(10) // Lấy nhiều hơn để đảm bảo có đủ dữ liệu sau khi sắp xếp
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Lỗi khi tải dữ liệu yêu cầu cứu trợ: ${snapshot.error}');
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Đã xảy ra lỗi khi tải dữ liệu'),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có yêu cầu cứu trợ nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Sắp xếp dữ liệu: "đang xác minh" lên đầu, sau đó đến "chấp nhận"
        var sortedDocs = snapshot.data!.docs.toList();
        sortedDocs.sort((a, b) {
          var statusA = (a.data() as Map<String, dynamic>)['sTrangThai'] as String?;
          var statusB = (b.data() as Map<String, dynamic>)['sTrangThai'] as String?;
          
          if (statusA == 'đang xác minh' && statusB != 'đang xác minh') {
            return -1; // A (đang xác minh) lên trước B
          } else if (statusA != 'đang xác minh' && statusB == 'đang xác minh') {
            return 1; // B (đang xác minh) lên trước A
          } else {
            // Nếu cùng trạng thái, sắp xếp theo thời gian mới nhất
            var dateA = (a.data() as Map<String, dynamic>)['tNgayGui'] as Timestamp?;
            var dateB = (b.data() as Map<String, dynamic>)['tNgayGui'] as Timestamp?;
            
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            
            return dateB.compareTo(dateA); // Mới nhất lên đầu
          }
        });
        
        // Giới hạn chỉ lấy 5 item đầu tiên sau khi sắp xếp
        if (sortedDocs.length > 5) {
          sortedDocs = sortedDocs.sublist(0, 5);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var request = sortedDocs[index].data() as Map<String, dynamic>;
            var requestId = sortedDocs[index].id;

            // Xác định màu dựa trên trạng thái
            Color statusColor;
            String statusText = request['sTrangThai'] ?? 'Không xác định';
            
            switch (statusText) {
              case 'đang xác minh':
                statusColor = Colors.orange;
                break;
              case 'chấp nhận':
                statusColor = Colors.green;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: statusColor.withAlpha(70),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChiTietYeuCauScreen(
                        requestId: requestId,
                        request: request,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh nếu có
                    if (request.containsKey('sHinhAnh') && request['sHinhAnh'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: request['sHinhAnh'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                      ),
                    
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị trạng thái
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Tiêu đề
                          Text(
                            request['sTieuDe'] ?? 'Yêu cầu cứu trợ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Mô tả cắt ngắn
                          Text(
                            request['sMoTa'] ?? 'Không có mô tả',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          
                          SizedBox(height: 10),
                          
                          // Địa điểm
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request['sViTri'] ?? 'Không có địa điểm',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 6),
                          
                          // Ngày gửi và ngày duyệt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (request['tNgayGui'] != null)
                                Text(
                                  'Ngày gửi: ${DateFormatter.formatDate(request['tNgayGui'])}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              
                              if (request['tNgayDuyet'] != null)
                                Text(
                                  'Ngày duyệt: ${DateFormatter.formatDate(request['tNgayDuyet'])}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            );
          },
        );
      },
    );
  }

  String _formatNewsDate(DateTime? date) {
    if (date == null) return 'Không rõ';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
