import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Lưu thông báo vào Firestore
  Future<void> saveNotification({
    required String title,
    required String body,
    String? topic,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'topic': topic ?? 'all',
        'additionalData': additionalData,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Lỗi khi lưu thông báo: $e');
      rethrow;
    }
  }
  
  // Gửi thông báo (thực tế phải được triển khai ở phía server)
  // Đây chỉ là mô phỏng, cần thay thế bằng Cloud Functions hoặc Backend Service
  Future<bool> sendNotification({
    required String title,
    required String body,
    String? topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Lưu thông báo vào Firestore
      await saveNotification(
        title: title,
        body: body,
        topic: topic,
        additionalData: data,
      );
      
      // Mô phỏng việc gửi thông báo thành công
      // Trong thực tế, bạn cần gọi API hoặc Cloud Functions
      
      return true;
    } catch (e) {
      debugPrint('Lỗi khi gửi thông báo: $e');
      return false;
    }
  }
  
  // Lấy danh sách thông báo từ Firestore
  Stream<QuerySnapshot> getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }
}