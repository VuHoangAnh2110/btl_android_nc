import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/common/feature_card.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/news_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../pages/news_detail_screen.dart';
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

          Text(
            'Yêu cầu cứu trợ gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('tblYeuCau')
          .where('sTrangThai', isEqualTo: 'chấp nhận')
          .orderBy('tNgayGui', descending: true)
          .limit(5)
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
            var request =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Colors.green.withAlpha(52),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                title: Text(
                  request['sTieuDe'] ?? 'Yêu cầu cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      request['sMoTa'] ?? 'Không có mô tả',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request['sViTri'] ?? 'Không có địa điểm',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã duyệt',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                isThreeLine: true,
              ),
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
