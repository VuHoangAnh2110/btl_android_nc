import 'package:btl_android_nc/widgets/common/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:maps_launcher/maps_launcher.dart';

class ChiTietYeuCauScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> request;

  const ChiTietYeuCauScreen({
    Key? key,
    required this.requestId,
    required this.request,
  }) : super(key: key);

  @override
  _ChiTietYeuCauScreenState createState() => _ChiTietYeuCauScreenState();
}

class _ChiTietYeuCauScreenState extends State<ChiTietYeuCauScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final imageUrl = request['sHinhAnh'] ?? '';
    final geoPoint = request['sToaDo'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết yêu cầu cứu trợ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card chính chứa thông tin
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh yêu cầu (nếu có)
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, size: 64),
                              ),
                            ),
                          ),

                        // Nội dung chi tiết
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tiêu đề
                              Text(
                                request['sTieuDe'] ?? 'Không có tiêu đề',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Trạng thái (bên trái)
                                  StatusBadge(status: request['sTrangThai'] ?? 'chờ duyệt'),
                                  
                                  // Mức độ (bên phải)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getMucDoColor(request['sMucDo'] ?? 'Thường').withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: _getMucDoColor(request['sMucDo'] ?? 'Thường'),
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          request['sMucDo'] ?? 'Chưa xác định',
                                          style: TextStyle(
                                            color:  Colors.black,// _getMucDoColor(request['sMucDo'] ?? 'Thường'),
                                            fontWeight: request['sMucDo'] == 'Khẩn cấp' ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 8),

                              // Mô tả chi tiết
                              _buildSectionTitle('Mô tả chi tiết'),
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  request['sMoTa'] ?? 'Không có mô tả',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),

                              SizedBox(height: 16),

                              // Thông tin địa điểm
                              _buildSectionTitle('Địa điểm'),
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      Icons.location_on,
                                      '',
                                      request['sViTri'] ?? 'Không có địa chỉ',
                                      Colors.red,
                                    ),
                                    
                                    SizedBox(height: 8),
                                    
                                    // Nút xem trên bản đồ
                                  ],
                                ),
                              ),

                              SizedBox(height: 16),

                              // Thông tin người gửi
                              _buildSectionTitle('Thông tin người gửi'),
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      Icons.person,
                                      'Tên:',
                                      request['userName'] ?? 'Không có thông tin',
                                      Colors.blue,
                                    ),
                                    
                                    SizedBox(height: 8),
                                    
                                    _buildInfoRow(
                                      Icons.phone,
                                      'Liên hệ:',
                                      request['userId'] ?? 'Không có thông tin',
                                      Colors.green,
                                      isPhone: true,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16),

                              // Thời gian
                              _buildSectionTitle('Thời gian'),
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Column(
                                  children: [
                                    if (request['tNgayGui'] != null)
                                      _buildInfoRow(
                                        Icons.calendar_today,
                                        'Ngày gửi:',
                                        DateFormatter.formatDate(request['tNgayGui']),
                                        Colors.deepPurple,
                                      ),
                                    
                                    SizedBox(height: 8),
                                    
                                    if (request['tNgayDuyet'] != null)
                                      _buildInfoRow(
                                        Icons.check_circle,
                                        'Ngày duyệt:',
                                        DateFormatter.formatDate(request['tNgayDuyet']),
                                        Colors.green,
                                      ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16),

                              // Người duyệt
                              _buildSectionTitle('Phê duyệt'),
                              if (request['sNguoiDuyet'] != null)
                                _buildInfoRow(
                                  Icons.verified_user,
                                  'Người duyệt:',
                                  request['sNguoiDuyet'],
                                  Colors.blue,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Nút gọi hỗ trợ
                  if (request['userId'] != null && request['userId'] != "Trống")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _makePhoneCall(request['userId']);
                        },
                        icon: Icon(Icons.call),
                        label: Text('Gọi hỗ trợ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Widget hiển thị tiêu đề section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // Widget hiển thị hàng thông tin
  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {bool isPhone = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Text(
          '$label ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: isPhone
              ? GestureDetector(
                  onTap: () => _makePhoneCall(value),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  // Hàm gọi điện thoại
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gọi điện: $e')),
      );
    }
  }

  // Hàm lấy màu dựa vào mức độ
  Color _getMucDoColor(String MucDo) {
    switch (MucDo) {
      case 'Khẩn cấp':
        return Colors.red;
      case 'Thường':
        return Colors.orange; 
      default:
        return Colors.blue;
    }
  }

}