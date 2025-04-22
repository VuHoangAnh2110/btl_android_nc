import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../widgets/common/status_badge.dart';

class AdminReliefRequestsTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const AdminReliefRequestsTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _AdminReliefRequestsTabState createState() => _AdminReliefRequestsTabState();
}

class _AdminReliefRequestsTabState extends State<AdminReliefRequestsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).primaryColor.withAlpha(26),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: 'Đang chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Đã từ chối'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList('pending'),
              _buildRequestsList('approved'),
              _buildRequestsList('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('reliefRequests')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  status == 'pending'
                      ? 'Không có yêu cầu nào đang chờ duyệt'
                      : status == 'approved'
                          ? 'Chưa có yêu cầu nào được duyệt'
                          : 'Chưa có yêu cầu nào bị từ chối',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var request =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var requestId = snapshot.data!.docs[index].id;

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _getStatusColor(status),
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  request['title'] ?? 'Yêu cầu cứu trợ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Người gửi: ${request['userName'] ?? 'Không có tên'}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Ngày gửi: ${DateFormatter.formatDate(request['createdAt'])}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: StatusBadge(status: status),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mô tả chi tiết:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(request['description'] ?? 'Không có mô tả'),
                        SizedBox(height: 16),

                        Text(
                          'Địa điểm:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  request['location'] ?? 'Không có địa điểm'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Thông tin liên hệ
                        Text(
                          'Thông tin liên hệ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.green),
                            SizedBox(width: 8),
                            Text(request['userId'] ??
                                'Không có thông tin liên hệ'),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Buttons
                        if (status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  // Xử lý từ chối
                                  try {
                                    await db
                                        .collection('reliefRequests')
                                        .doc(requestId)
                                        .update({'status': 'rejected'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Đã từ chối yêu cầu')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.close, color: Colors.red),
                                label: Text('Từ chối'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Xử lý phê duyệt
                                  try {
                                    await db
                                        .collection('reliefRequests')
                                        .doc(requestId)
                                        .update({'status': 'approved'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã phê duyệt yêu cầu'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.check),
                                label: Text('Phê duyệt'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),

                        if (status != 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  // Xóa yêu cầu
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Xác nhận xóa'),
                                      content: Text(
                                          'Bạn có chắc muốn xóa yêu cầu này không?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            try {
                                              await db
                                                  .collection('reliefRequests')
                                                  .doc(requestId)
                                                  .delete();

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content:
                                                        Text('Đã xóa yêu cầu')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text('Lỗi: $e')),
                                              );
                                            }
                                          },
                                          child: Text('Xóa'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Icon(Icons.delete, color: Colors.red),
                                label: Text('Xóa yêu cầu'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
