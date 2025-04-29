import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../chi_tiet_yeu_cau_screen.dart';
import 'admin_permission_mixin.dart';
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
    with SingleTickerProviderStateMixin, AdminPermissionMixin {
  late TabController _tabController;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    checkAdminPermission(context, widget.userData, widget.isLoggedIn);
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
            //isScrollable: true,  // Cho phép cuộn nếu nhiều tab
            tabs: [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Chờ duyệt',
              ),
              Tab(
                icon: Icon(Icons.fact_check),
                text: 'Xác minh',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Đã duyệt',
              ),
              Tab(
                icon: Icon(Icons.cancel_outlined),
                text: 'Đã từ chối',
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList('chờ duyệt'),
              _buildRequestsList('chờ xác minh'),
              _buildRequestsList('chấp nhận'),
              _buildRequestsList('từ chối'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('tblYeuCau')
          .where('sTrangThai', isEqualTo: status)
          .orderBy('sMucDo', descending: false) 
          .orderBy('tNgayGui', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Lỗi khi tải dữ liệu: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                SizedBox(height: 16),
                Text('Không thể tải dữ liệu yêu cầu',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
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
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  status == 'chờ duyệt'
                      ? 'Không có yêu cầu nào đang chờ duyệt'
                      : status == 'chờ xác minh'
                          ? 'Chưa có yêu cầu nào chờ xác minh'
                          : 'Chưa có yêu cầu nào được duyệt',
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
            var request = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var requestId = snapshot.data!.docs[index].id;
            bool isKhanCap = request['sMucDo'] == 'Khẩn cấp';

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isKhanCap ? Colors.red : _getStatusColor(status),
                  width: isKhanCap ? 2 : 1,
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
                        // isAdmin: true, // Thêm tham số để phân biệt (phát triển)
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          request['sTieuDe'] ?? 'Yêu cầu cứu trợ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isKhanCap ? Colors.red : null,
                          ),
                        ),
                      ),
                      // if (isKhanCap)
                      //   Container(
                      //     margin: EdgeInsets.only(left: 8),
                      //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red.withOpacity(0.1),
                      //       borderRadius: BorderRadius.circular(10),
                      //       border: Border.all(color: Colors.red, width: 1),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(
                      //           Icons.warning_amber_rounded,
                      //           color: Colors.red,
                      //           size: 16,
                      //         ),
                      //         SizedBox(width: 4),
                      //         Text('KHẨN CẤP',
                      //           style: TextStyle(
                      //             color: Colors.red,
                      //             fontWeight: FontWeight.bold,
                      //             fontSize: 12,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Người gửi: ${request['userName'] ?? 'Không có tên'}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Ngày gửi: ${DateFormatter.formatDate(request['tNgayGui'])}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: status),
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mô tả chi tiết:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(request['sMoTa'] ?? 'Không có mô tả'),
                          SizedBox(height: 16),

                          Text('Địa điểm:',
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
                                    request['sViTri'] ?? 'Không có địa điểm'),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          Text('Thông tin liên hệ:',
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
                              Text(request['userId'] ?? 'Không có thông tin liên hệ'),
                            ],
                          ),

                          SizedBox(height: 15),

                          if (status == 'chờ duyệt')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    // Xử lý từ chối
                                    try {
                                      await db
                                          .collection('tblYeuCau')
                                          .doc(requestId)
                                          .update({
                                            'sTrangThai': 'từ chối',
                                            'tNgayDuyet': Timestamp.now(), 
                                            'sNguoiDuyet': widget.userData?['name'] ?? 'Admin',
                                            'sSDTNguoiDuyet': widget.userData?['phone'] ?? 'Trống'
                                          });

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
                                          .collection('tblYeuCau')
                                          .doc(requestId)
                                          .update({
                                            'sTrangThai': 'chờ xác minh',
                                            'tNgayDuyet': Timestamp.now(), 
                                            'sNguoiDuyet': widget.userData?['name'] ?? 'Admin', 
                                            'sSDTNguoiDuyet': widget.userData?['phone'] ?? 'Trống'
                                          });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đang xác minh yêu cầu'),
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
                                  label: Text('Xác minh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 233, 156, 69),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                          if (status == 'chờ xác minh')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    // Xử lý từ chối
                                    try {
                                      await db
                                          .collection('tblYeuCau')
                                          .doc(requestId)
                                          .update({
                                            'sTrangThai': 'từ chối',
                                            'tNgayDuyet': Timestamp.now(), 
                                            'sNguoiDuyet': widget.userData?['name'] ?? 'Admin',
                                            'sSDTNguoiDuyet': widget.userData?['phone'] ?? 'Trống'
                                          });

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
                                          .collection('tblYeuCau')
                                          .doc(requestId)
                                          .update({
                                            'sTrangThai': 'chấp nhận',
                                            'tNgayDuyet': Timestamp.now(), 
                                            'sNguoiDuyet': widget.userData?['name'] ?? 'Admin', 
                                            'sSDTNguoiDuyet': widget.userData?['phone'] ?? 'Trống'
                                          });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đang xác minh yêu cầu'),
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
                                  label: Text('phê duyệt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          
                          if (status != 'chờ duyệt' && status != 'chờ xác minh')
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
                                        content: Text('Bạn có chắc muốn xóa yêu cầu này không?'),
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
                                                    .collection('tblYeuCau')
                                                    .doc(requestId)
                                                    .delete();

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                      content: Text('Đã xóa yêu cầu')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
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
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
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
                                icon: Icon(Icons.visibility),
                                label: Text('Xem chi tiết'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
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
