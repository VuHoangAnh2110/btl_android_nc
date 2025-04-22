import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../widgets/common/feature_card.dart';
import '../../../../utils/date_formatter.dart';

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
    // Thay thế bằng code lấy tin tức từ RSS sau khi tạo NewsService
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
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
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cloudy_snowing, color: Colors.blue),
            ),
            title: Text(
              'Dự báo thời tiết ngày ${index + 1}/5/2025',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Cảnh báo mưa lớn tại khu vực miền Trung và Tây Nguyên...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              // Xử lý khi nhấn vào tin tức
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentReliefsSection() {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('reliefRequests')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
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
                  request['title'] ?? 'Yêu cầu cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      request['description'] ?? 'Không có mô tả',
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
                            request['location'] ?? 'Không có địa điểm',
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
}
