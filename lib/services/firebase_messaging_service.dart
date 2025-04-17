import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý thông báo khi ứng dụng đang ở nền
  debugPrint('Xử lý thông báo nền: ${message.notification?.title}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _fcmToken;
  
  // Getter cho FCM token
  String? get fcmToken => _fcmToken;

  Future<void> init({
    bool skipPermissionRequest = false, 
    bool skipTokenSave = false
  }) async {
    // Đảm bảo Firebase đã được khởi tạo
    await Firebase.initializeApp();
    
    // Thiết lập handler cho thông báo
    setupNotificationHandlers();
    
    // Yêu cầu quyền nếu cần
    bool hasPermission = skipPermissionRequest ? true : await requestNotificationPermissions();
    
    // Chỉ lấy và lưu token nếu có quyền và không bỏ qua bước lưu token
    if (hasPermission && !skipTokenSave) {
      await getAndSaveFCMToken();
      
      // Lắng nghe khi token được làm mới
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token được làm mới: $newToken');
        _fcmToken = newToken;
        saveFCMToken(newToken);
      });
    } else {
      debugPrint('Không lưu FCM token do: ${!hasPermission ? "không có quyền" : "yêu cầu bỏ qua"}');
    }
  }

  Future<bool> requestNotificationPermissions() async {
    bool isGranted = false;
    
    // Yêu cầu quyền thông báo từ Firebase Messaging
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Người dùng đã cấp quyền thông báo');
      isGranted = true;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Người dùng đã cấp quyền thông báo tạm thời');
      isGranted = true;
    } else {
      debugPrint('Quyền thông báo bị từ chối hoặc hạn chế');
      isGranted = false;
    }
    
    return isGranted;
  }

  Future<String?> getAndSaveFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        await saveFCMToken(_fcmToken!);
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('Lỗi khi lấy FCM token: $e');
      return null;
    }
  }

  Future<void> saveFCMToken(String token) async {
    try {
      await _firestore.collection('device_tokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        'device': Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Other'),
        'userId': null,
      }, SetOptions(merge: true));
      
      debugPrint('FCM token đã được lưu trong Firestore');
    } catch (e) {
      debugPrint('Lỗi khi lưu FCM token: $e');
    }
  }
  
  Future<void> updateTokenWithUserId(String userId) async {
    if (_fcmToken == null) {
      // Thử lấy token nếu chưa có
      await getAndSaveFCMToken();
    }
    
    if (_fcmToken != null) {
      try {
        await _firestore.collection('device_tokens').doc(_fcmToken).update({
          'userId': userId,
          'lastLoggedIn': FieldValue.serverTimestamp(),
        });
        debugPrint('Đã liên kết FCM token với người dùng: $userId');
      } catch (e) {
        debugPrint('Lỗi khi liên kết FCM token với người dùng: $e');
      }
    }
  }

  void setupNotificationHandlers() {
    // Xử lý tin nhắn khi ứng dụng đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Nhận được thông báo khi ứng dụng đang mở: ${message.notification?.title}');
    });
    
    // Xử lý khi người dùng nhấp vào thông báo để mở ứng dụng
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Ứng dụng được mở từ thông báo: ${message.notification?.title}');
      _handleMessage(message);
    });

    // Xử lý khi click vào thông báo để mở app từ trạng thái terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
  }

  // Xử lý khi người dùng click vào thông báo
  void _handleMessage(RemoteMessage message) {
    // Điều hướng đến màn hình tương ứng dựa vào data trong message
    debugPrint('Xử lý click thông báo: ${message.data}');
  }
  
  // Đăng ký theo dõi một topic
  Future<void> subscribeToTopic(String topic) async {
    // Kiểm tra quyền trước khi đăng ký topic
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Đã đăng ký theo dõi topic: $topic');
  }
  
  // Hủy đăng ký theo dõi một topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Đã hủy đăng ký theo dõi topic: $topic');
  }
}