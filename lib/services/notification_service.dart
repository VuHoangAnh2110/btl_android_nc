import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiUrl = 'https://android-nc-fcm.onrender.com/api/send-notification';
  
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
  
  // Gửi thông báo qua API
  Future<bool> sendNotification({
    required String title,
    required String body,
    String? topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Chuẩn bị dữ liệu gửi đi
      final payload = {
        'title': title,
        'body': body,
        'topic': topic ?? 'all',
      };
      
      // Thực hiện POST request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      // Kiểm tra response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Gửi thông báo thành công: ${response.body}');
        
        // Lưu thông báo vào Firestore
        await saveNotification(
          title: title,
          body: body,
          topic: topic,
          additionalData: data,
        );
        
        return true;
      } else {
        debugPrint('Lỗi khi gửi thông báo: ${response.statusCode} - ${response.body}');
        return false;
      }
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