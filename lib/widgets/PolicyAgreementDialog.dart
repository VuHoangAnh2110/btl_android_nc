import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PolicyAgreementDialog {
  static final String _policyKey = 'policy_agreed';

  // Kiểm tra và hiển thị dialog nếu cần
  static Future<void> showIfNeeded(BuildContext context, bool isAdmin) async {
    // Nếu là admin, không hiển thị
    if (isAdmin) return;

    // Kiểm tra xem người dùng đã đồng ý chưa
    final prefs = await SharedPreferences.getInstance();
    final bool agreed = prefs.getBool(_policyKey) ?? false;

    // Nếu chưa đồng ý, hiện dialog
    if (!agreed && context.mounted) {
      await _showDialog(context);
    }
  }

  // Hiển thị dialog
  static Future<void> _showDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Không cho phép đóng bằng cách nhấn bên ngoài
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          // Ngăn người dùng nhấn nút back
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(
              'Chính sách sử dụng',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khi sử dụng ứng dụng Hỗ Trợ Thiên Tai, bạn đồng ý với các điều khoản sau:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  _buildPolicyItem(context,
                      'Ứng dụng sẽ thu thập vị trí của bạn để cung cấp thông tin cứu hộ chính xác.'),
                  _buildPolicyItem(context,
                      'Dữ liệu cá nhân sẽ được bảo mật và chỉ sử dụng cho mục đích cứu hộ.'),
                  _buildPolicyItem(context,
                      'Chúng tôi không chịu trách nhiệm về các thông tin không chính xác được cung cấp bởi người dùng.'),
                  _buildPolicyItem(context,
                      'Ứng dụng có thể gửi thông báo về tình hình thiên tai và hướng dẫn di tản.'),
                  _buildPolicyItem(context,
                      'Bạn đồng ý sử dụng ứng dụng đúng mục đích và không lạm dụng dịch vụ.'),
                ],
              ),
            ),
            actions: <Widget>[
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Lưu trạng thái đã đồng ý
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_policyKey, true);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Tôi đồng ý với các điều khoản'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildPolicyItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle,
                size: 8, color: Theme.of(context).primaryColor),
          ),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  // Phương thức để reset việc đồng ý (cho mục đích phát triển)
  static Future<void> resetAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_policyKey);
  }
  // Thêm phương thức public này vào lớp PolicyAgreementDialog

// Hiển thị dialog bất kể người dùng đã đồng ý hay chưa
  static Future<void> show(BuildContext context) async {
    return _showDialog(context);
  }
}
