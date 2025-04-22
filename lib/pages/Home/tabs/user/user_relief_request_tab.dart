import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../widgets/common/status_badge.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

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
                          ),
                        ),
                        SizedBox(height: 20),
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

                              try {
                                await db.collection('reliefRequests').add({
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'location': _locationController.text,
                                  'userId': widget.userData?[
                                      'phone'], // Sử dụng phone làm userId
                                  'userName':
                                      widget.userData?['name'] ?? 'Người dùng',
                                  'createdAt': Timestamp.now(),
                                  'status': 'pending',
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Yêu cầu cứu trợ đã được gửi thành công'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Xóa input
                                _titleController.clear();
                                _descriptionController.clear();
                                _locationController.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.send),
                            label: Text('Gửi yêu cầu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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

          // Yêu cầu của tôi
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
                  .collection('reliefRequests')
                  .where('userId', isEqualTo: widget.userData?['phone'])
                  .orderBy('createdAt', descending: true)
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
                    String status = request['status'] ?? 'pending';

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
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    request['title'] ?? 'Yêu cầu cứu trợ',
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
                            Text(request['description'] ?? 'Không có mô tả'),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    request['location'] ?? 'Không có địa điểm',
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
                                  'Ngày tạo: ${DateFormatter.formatDate(request['createdAt'])}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (status == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await db
                                            .collection('reliefRequests')
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
                                    child: Text('Xóa yêu cầu'),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
