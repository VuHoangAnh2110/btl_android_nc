import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/date_formatter.dart';
import '../../../../services/notification_service.dart';

class AdminNotificationsTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const AdminNotificationsTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _AdminNotificationsTabState createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Gửi thông báo khẩn cấp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề thông báo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Nội dung thông báo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_titleController.text.isEmpty ||
                            _bodyController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Hiển thị hộp thoại xác nhận
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Xác nhận gửi thông báo khẩn cấp'),
                            content: Text('Bạn có chắc muốn gửi thông báo khẩn cấp này đến tất cả người dùng?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Lưu context gốc trước khi đóng dialog
                                  final originContext = context;
                                  Navigator.pop(context);

                                  // Tạo một biến để theo dõi dialog loading
                                  BuildContext? loadingDialogContext;

                                  // Hiển thị loading
                                  showDialog(
                                    context: originContext,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      // Lưu context của dialog loading
                                      loadingDialogContext = context;
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );

                                  try {
                                    // Gửi thông báo
                                    bool success = await _notificationService.sendNotification(
                                      title: _titleController.text,
                                      body: _bodyController.text,
                                      topic: 'all',
                                    );

                                    // Đóng dialog loading nếu nó vẫn hiển thị
                                    if (loadingDialogContext != null) {
                                      Navigator.of(loadingDialogContext!).pop();
                                    }

                                    // Sử dụng context gốc để hiển thị thông báo kết quả
                                    if (originContext.mounted) {
                                      ScaffoldMessenger.of(originContext).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Thông báo đã được gửi thành công!'
                                                : 'Không thể gửi thông báo. Vui lòng thử lại sau.',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );

                                      if (success) {
                                        // Xóa input nếu gửi thành công
                                        setState(() {
                                          _titleController.clear();
                                          _bodyController.clear();
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    // Đóng dialog loading nếu nó vẫn hiển thị
                                    if (loadingDialogContext != null) {
                                      Navigator.of(loadingDialogContext!).pop();
                                    }

                                    // Hiển thị lỗi
                                    if (originContext.mounted) {
                                      ScaffoldMessenger.of(originContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text('Gửi'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.send),
                      label: Text('Gửi thông báo khẩn cấp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
            ),
          ),

          SizedBox(height: 20),

          // Lịch sử thông báo đã gửi
          Text(
            'Lịch sử thông báo đã gửi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: _notificationService.getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Chưa có thông báo nào được gửi'),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var notification = snapshot.data!.docs[index];
                  var data = notification.data() as Map<String, dynamic>;
                  Timestamp? sentAt = data['sentAt'] as Timestamp?;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        data['title'] ?? 'Không có tiêu đề',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['body'] ?? 'Không có nội dung'),
                          SizedBox(height: 5),
                          Text(
                            'Gửi đến: ${data['topic'] ?? 'all'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (sentAt != null)
                            Text(
                              'Thời gian: ${DateFormatter.formatDate(sentAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
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
}
