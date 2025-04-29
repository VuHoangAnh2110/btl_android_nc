import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/date_formatter.dart';
import './chi_tiet_yeu_cau_screen.dart';

class XemTatCaYeuCau extends StatefulWidget {
  const XemTatCaYeuCau({Key? key}) : super(key: key);

  @override
  _XemTatCaYeuCauState createState() => _XemTatCaYeuCauState();
}

class _XemTatCaYeuCauState extends State<XemTatCaYeuCau> {
  String? _trangThaiFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tất cả yêu cầu cứu trợ'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(Icons.filter_list),
            tooltip: 'Lọc theo trạng thái',
            onSelected: (value) {
              setState(() {
                _trangThaiFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('Tất cả'),
              ),
              PopupMenuItem(
                value: 'chờ xác minh',
                child: Text('chờ xác minh'),
              ),
              PopupMenuItem(
                value: 'chấp nhận',
                child: Text('Đã chấp nhận'),
              ),
            ],
          ),
        ],
      ),
      body: _buildDanhSachYeuCau(),
    );
  }

  Widget _buildDanhSachYeuCau() {
    final db = FirebaseFirestore.instance;
    Query query = db.collection('tblYeuCau');
    
    // Áp dụng filter từ UI nếu có
    if (_trangThaiFilter != null) {
      query = query.where('sTrangThai', isEqualTo: _trangThaiFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Đã xảy ra lỗi khi tải dữ liệu'),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: Icon(Icons.refresh),
                  label: Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  _trangThaiFilter == null 
                      ? 'Không có yêu cầu cứu trợ nào'
                      : 'Không có yêu cầu cứu trợ trạng thái "$_trangThaiFilter"',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Lọc dữ liệu: chỉ giữ lại các yêu cầu chờ xác minh và yêu cầu chấp nhận không phải khẩn cấp
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var trangThai = data['sTrangThai'] as String?;
          var mucDo = data['sMucDo'] as String?;
          
          // Giữ lại tất cả yêu cầu chờ xác minh
          if (trangThai == 'chờ xác minh') {
            return true;
          }
          
          // Loại bỏ các yêu cầu "chờ duyệt", "từ chối", và "chấp nhận" mà là khẩn cấp
          if (trangThai == 'chờ duyệt' || trangThai == 'từ chối') {
            return false;
          }
          
          
          return true;
        }).toList();

        // Sắp xếp: "chờ xác minh" lên đầu, sau đó đến các trạng thái khác
        docs.sort((a, b) {
          var statusA = (a.data() as Map<String, dynamic>)['sTrangThai'] as String?;
          var statusB = (b.data() as Map<String, dynamic>)['sTrangThai'] as String?;
          
          // Ưu tiên "chờ xác minh" lên đầu
          if (statusA == 'chờ xác minh' && statusB != 'chờ xác minh') {
            return -1;
          } else if (statusA != 'chờ xác minh' && statusB == 'chờ xác minh') {
            return 1;
          } else {
            // Nếu cùng trạng thái, sắp xếp theo thời gian, mới nhất lên trước
            var dateA = (a.data() as Map<String, dynamic>)['tNgayGui'] as Timestamp?;
            var dateB = (b.data() as Map<String, dynamic>)['tNgayGui'] as Timestamp?;
            
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            
            return dateB.compareTo(dateA);
          }
        });

        // Kiểm tra nếu không có yêu cầu nào sau khi lọc
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không có yêu cầu cứu trợ phù hợp với điều kiện',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var request = docs[index].data() as Map<String, dynamic>;
            var requestId = docs[index].id;

            // Xác định màu dựa trên trạng thái
            Color statusColor;
            IconData statusIcon;
            
            switch(request['sTrangThai']) {
              case 'chờ xác minh':
                statusColor = Colors.orange;
                statusIcon = Icons.pending_actions;
                break;
              case 'chấp nhận':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                break;
              case 'từ chối':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              case 'hoàn thành':
                statusColor = Colors.blue;
                statusIcon = Icons.task_alt;
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.help_outline;
            }

            // Hiển thị card yêu cầu (giữ nguyên phần hiển thị)
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
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
                    if (request.containsKey('sHinhAnh') &&
                        request['sHinhAnh'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: request['sHinhAnh'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge trạng thái
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon,
                                        size: 16, color: statusColor),
                                    SizedBox(width: 5),
                                    Text(
                                      request['sTrangThai'] ?? 'Không xác định',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Spacer(),

                              // Mức độ nếu có
                              if (request['sMucDo'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: request['sMucDo'] == 'Khẩn cấp'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: request['sMucDo'] == 'Khẩn cấp'
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                  ),
                                  child: Text(
                                    request['sMucDo'],
                                    style: TextStyle(
                                      color: request['sMucDo'] == 'Khẩn cấp'
                                          ? Colors.red
                                          : Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Tiêu đề
                          Text(
                            request['sTieuDe'] ?? 'Yêu cầu cứu trợ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          SizedBox(height: 8),

                          // Mô tả cắt ngắn
                          Text(
                            request['sMoTa'] ?? 'Không có mô tả',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 12),

                          // Địa điểm
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request['sViTri'] ?? 'Không có địa điểm',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Ngày gửi và ngày duyệt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (request['tNgayGui'] != null)
                                Expanded(
                                  child: Text(
                                    'Ngày gửi: ${DateFormatter.formatDate(request['tNgayGui'])}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (request['tNgayDuyet'] != null)
                                Expanded(
                                  child: Text(
                                    'Ngày duyệt: ${DateFormatter.formatDate(request['tNgayDuyet'])}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                            ],
                          ),
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
}
