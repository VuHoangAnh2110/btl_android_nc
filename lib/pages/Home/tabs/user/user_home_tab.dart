import 'package:btl_android_nc/pages/chi_tiet_yeu_cau_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/common/feature_card.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/news_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../pages/news_detail_screen.dart';
import '../../../../pages/chi_tiet_yeu_cau_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';

class UserHomeTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const UserHomeTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              color: Theme.of(context).colorScheme.primary.withAlpha(52),
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

          SizedBox(height: 30),

          // Bản đồ
          Text(
            'Bản đồ vùng thiên tai',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildMapSection(),

          SizedBox(height: 30),

          // Tin tức thời tiết
          Text(
            'Tin tức thời tiết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildNewsSection(),

          SizedBox(height: 30),

          // Yêu cầu cứu trợ gần đây
          Text(
            'Yêu cầu cứu trợ gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildRecentReliefsSection(),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 50, color: Colors.grey[600]),
            SizedBox(height: 10),
            Text(
              'Bản đồ đang được cập nhật',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
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
                    if (item['pubDate'] != null)
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
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('tblYeuCau')
          .where('sTrangThai', isEqualTo: 'chấp nhận')
          .where('sMucDo', isEqualTo: 'Thường')          
          .orderBy('tNgayGui', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Ghi log lỗi để theo dõi, không hiển thị chi tiết cho người dùng
          debugPrint('Lỗi khi tải dữ liệu yêu cầu cứu trợ: ${snapshot.error}');
          
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.orange,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không thể tải dữ liệu yêu cầu cứu trợ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Thực hiện fresh build context - đây là cách đơn giản
                      // nhưng trong ứng dụng thực tế, bạn có thể cần cách tốt hơn để refresh stream
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Không có yêu cầu cứu trợ gần đây'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var request = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var requestId = snapshot.data!.docs[index].id;

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.green.withAlpha(70),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Chuyển đến trang chi tiết yêu cầu
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

  String _formatNewsDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
