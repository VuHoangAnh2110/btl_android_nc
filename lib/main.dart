import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/DangNhap/DangNhap.dart';
import 'pages/Home/Home.dart';
import 'pages/DangKy/DangKy.dart';
import 'services/firebase_messaging_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
// Khai báo biến FirebaseFirestore toàn cục nếu bạn muốn sử dụng ở nhiều nơi
final FirebaseFirestore db = FirebaseFirestore.instance;
final FirebaseMessagingService messagingService = FirebaseMessagingService();
// Hàm xử lý thông báo nền cần khai báo ở top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Xử lý thông báo nền: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  bool hasPermission = await _requestNotificationPermission();
  
  // Khởi tạo dịch vụ FCM và lưu token chỉ khi được cấp quyền
  if (hasPermission) {
    await messagingService.init(skipPermissionRequest: true); // Skip vì đã yêu cầu ở trên
  } else {
    await messagingService.init(skipTokenSave: true); // Không lưu token khi không có quyền
  }

  runApp(const MyApp());
}

Future<bool> _requestNotificationPermission() async {
  bool granted = false;
  
  if (Platform.isIOS) {
    // Logic iOS không thay đổi
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true, 
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    granted = settings.authorizationStatus == AuthorizationStatus.authorized || 
              settings.authorizationStatus == AuthorizationStatus.provisional;
  } 
  else if (Platform.isAndroid) {
    // Thay vì dùng device_info_plus, sử dụng kiểm tra quyền trực tiếp
    // Nếu permission_handler trả về permanentlyDenied, tức là đã hiển thị dialog rồi
    // và người dùng đã từ chối và chọn "Không hỏi lại"
    
    // Trên Android cần kiểm tra quyền POST_NOTIFICATIONS mới bắt buộc từ Android 13 (SDK 33)
    // Đối với Android < 13, không cần yêu cầu quyền này
    PermissionStatus status = await Permission.notification.status;
    
    if (status.isPermanentlyDenied) {
      // Nếu người dùng đã từ chối vĩnh viễn, báo cáo và không hiển thị lại dialog
      debugPrint('Người dùng đã từ chối vĩnh viễn quyền thông báo, cần vào cài đặt ứng dụng');
      granted = false;
    } else {
      // Yêu cầu quyền cho mọi phiên bản Android
      // Trên Android < 13, quyền này sẽ tự động được cấp
      // Trên Android >= 13, hộp thoại quyền sẽ hiển thị
      PermissionStatus result = await Permission.notification.request();
      granted = result.isGranted;
      debugPrint('Kết quả yêu cầu quyền thông báo: $result (granted: $granted)');
    }
  }
  
  debugPrint('Trạng thái quyền thông báo cuối cùng: ${granted ? "Đã cấp" : "Từ chối"}');
  return granted;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hỗ Trợ Thiên Tai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      // Luôn bắt đầu ở trang Home, không kiểm tra trạng thái đăng nhập
      initialRoute: '/home',
      routes: {
        '/dangnhap': (context) => Dangnhap(),
        '/dangky': (context) => Dangky(),
        '/home': (context) => Home(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
