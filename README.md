# btl_android_nc

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

--------------------------------------------------------------------------
# 🚀 Hướng Dẫn Cài Đặt & Lập Trình Dự Án Flutter

## 📌 Yêu Cầu Hệ Thống
Trước khi bắt đầu, hãy đảm bảo bạn đã cài đặt các công cụ cần thiết:

- **Flutter SDK**: [Tải về tại đây](https://flutter.dev/docs/get-started/install)
- **Android Studio** (hoặc Xcode nếu phát triển iOS)
- **Visual Studio Code** (hoặc IntelliJ/Android Studio nếu bạn thích)
- **Git** (để làm việc nhóm)

## 🔧 Cài Đặt Môi Trường
### 1️⃣ Kiểm tra Flutter
Sau khi cài đặt Flutter, mở terminal/cmd và chạy lệnh:
```sh
flutter doctor
```
Lệnh này kiểm tra xem môi trường của bạn đã được thiết lập đầy đủ chưa.

### 2️⃣ Cấu hình thiết bị ảo
Nếu chạy trên **Android**, cần bật **Android Emulator** hoặc kết nối điện thoại qua USB:
```sh
flutter devices
```
Nếu dùng **iOS**, hãy mở **Xcode** và chạy Simulator.

## 📂 Clone và Khởi Chạy Dự Án
### 1️⃣ Clone repository
```sh
git clone https://github.com/your-repo.git
cd your-repo
```

### 2️⃣ Cài đặt dependencies
```sh
flutter pub get
```

### 3️⃣ Chạy ứng dụng
```sh
flutter run
```

Nếu muốn chạy trên thiết bị cụ thể:
```sh
flutter run -d <device_id>
```

## 📜 Quy Tắc Commit & Làm Việc Nhóm
- **Tạo branch mới** trước khi làm tính năng mới:
  ```sh
  git checkout -b feature/tinh-nang-moi
  ```
- **Commit theo chuẩn**:
  ```sh
  git commit -m "feat: Thêm màn hình đăng nhập"
  ```
- **Luôn pull code trước khi push**:
  ```sh
  git pull origin main
  git push origin feature/tinh-nang-moi
  ```

## 🛠️ Xử Lý Lỗi Thường Gặp
1. **Không nhận thiết bị** → Kiểm tra USB Debugging đã bật trên điện thoại.
2. **Lỗi phiên bản Flutter** → Chạy `flutter upgrade`.
3. **Lỗi build Android** → Xóa cache và chạy lại:
   ```sh
   flutter clean
   flutter pub get
   ```

📢 Nếu gặp lỗi khác, vui lòng tạo issue trên GitHub hoặc hỏi trong nhóm.

-
🎯 **Chúc bạn code vui vẻ!** 🚀

---------------------------------------------------------------------------------
Link figma: https://www.figma.com/board/vgxKLwPdiVXUuJZCZhBkMz/Prototyping-Example-(Copy)?node-id=0-1&t=w568l6ef8Yxb881P-1

# Hướng Dẫn Thiết Lập Firebase Cho Dự Án Flutter

## 1. Clone Dự Án
Trước tiên, bạn cần clone dự án từ repository:
```sh
git clone <repo_link>
cd <project_name>
```

Sau đó, chạy lệnh để tải dependencies:
```sh
flutter pub get
```

---

## 2. Cấu Hình Firebase
Để Firebase hoạt động trên máy của bạn, cần thiết lập các file cấu hình Firebase theo hướng dẫn dưới đây.

### 🔥 **Android**
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn dự án đã được tạo sẵn.
3. Vào **Project Settings** → Tab **General**.
4. Trong phần **"Your apps"**, chọn **app Android**.
5. **Tải file** `google-services.json` và đặt vào thư mục:
   ```
   android/app/google-services.json
   ```

### 🍏 **iOS**
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn dự án Firebase.
3. Vào **Project Settings** → Tab **General**.
4. Chọn **app iOS**.
5. **Tải file** `GoogleService-Info.plist` và đặt vào thư mục:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

---

## 3. Kiểm Tra Firebase Đã Hoạt Động
Chạy lệnh sau để đảm bảo Firebase được kết nối đúng cách:
```sh
flutterfire configure
```

Nếu Firebase chưa được liên kết, lệnh này sẽ tự động cập nhật cấu hình Firebase cho dự án.

---

## 4. Chạy Ứng Dụng
Sau khi thiết lập xong, chạy ứng dụng bằng lệnh:
```sh
flutter run
```

Nếu gặp lỗi, kiểm tra lại:
- Đã thêm đúng `google-services.json` và `GoogleService-Info.plist` chưa?
- Đã chạy `flutter pub get` chưa?
- Firebase Rules có đúng không? (Đảm bảo quyền truy cập dữ liệu hợp lý)

Chúc bạn thành công! 🚀

