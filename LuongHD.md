
# Luồng Hoạt Động Của Ứng Dụng Từ Lúc Đăng Nhập

## 1. Quá trình đăng nhập

### Nhập thông tin đăng nhập:
- Người dùng truy cập màn hình đăng nhập (`DangNhap.dart`)
- Nhập **số điện thoại** và **mật khẩu**
- Bấm nút **"ĐĂNG NHẬP"**

### Xác thực người dùng:
- Hệ thống kiểm tra các trường nhập liệu (**validation**)
- Hiển thị **trạng thái loading** (vòng tròn quay)
- Truy vấn **Firestore** để tìm người dùng có số điện thoại và mật khẩu khớp

### Xử lý kết quả đăng nhập:
- **Nếu không tìm thấy:**
  - Hiển thị thông báo lỗi: `"Số điện thoại hoặc mật khẩu không đúng"`
- **Nếu tìm thấy:**
  - Lấy dữ liệu người dùng từ Firestore
  - Kiểm tra quyền admin:  
    ```dart
    isAdmin = userData.containsKey('isAdmin') ? userData['isAdmin'] ?? false : false
    ```
  - Cập nhật trạng thái đăng nhập: `isLoggedIn = true` trong Firestore
  - Hiển thị thông báo đăng nhập thành công với quyền tương ứng
  - **Chuyển đến màn hình chính (Home)**

---

## 2. Xác định quyền và hiển thị giao diện

### Khởi tạo màn hình Home:
- Màn hình Home nhận tham số `isAdmin` từ màn hình đăng nhập
- Trong `initState()`, gọi `fetchUserData()` để lấy thông tin người dùng hiện tại

### Lấy và cập nhật thông tin người dùng:
- `fetchUserData()` truy vấn Firestore tìm người dùng có `isLoggedIn = true`
- Cập nhật biến `userData` với thông tin người dùng
- Cập nhật `isLoggedIn = true` và `isActuallyAdmin` dựa trên dữ liệu thực tế

### Quyết định hiển thị giao diện:
- Sử dụng:
  ```dart
  showAdminInterface = widget.isAdmin || isActuallyAdmin
  ```
- Hiển thị giao diện tương ứng với quyền của người dùng

---

## 3. Giao diện theo vai trò người dùng

### A. Đối với **Admin**:

#### Thanh tiêu đề (AppBar):
- Tiêu đề: `"Trang quản trị"`
- Hiển thị biểu tượng admin
- Nút **Đăng xuất** ở góc phải

#### Các tab chính:

##### **Tab 1: Quản lý người dùng**
- Hiển thị danh sách người dùng từ Firestore
- Cho phép **cấp/thu hồi quyền admin**
- Cho phép **xóa người dùng**

##### **Tab 2: Gửi thông báo khẩn**
- Form gửi thông báo khẩn cấp đến tất cả người dùng
- Hiển thị lịch sử thông báo đã gửi

##### **Tab 3: Yêu cầu cứu trợ**
- Hiển thị danh sách yêu cầu cứu trợ từ người dùng
- Cho phép **phê duyệt/từ chối** yêu cầu
- Hiển thị các trạng thái:
  - Đang chờ
  - Đã duyệt
  - Đã từ chối

---

### B. Đối với **Người dùng**:

#### Thanh tiêu đề (AppBar):
- Tiêu đề: `"Trang chủ"`
- Nút **Đăng xuất** ở góc phải

#### Các tab chính:

##### **Tab 1: Trang chủ**
- Banner chào mừng với tên người dùng
- Hiển thị **bản đồ vùng thiên tai**
- **Tin tức thời tiết**
- Yêu cầu cứu trợ đã được phê duyệt gần đây

##### **Tab 2: Yêu cầu cứu trợ**
- Form gửi **yêu cầu cứu trợ mới**
- Danh sách yêu cầu cứu trợ của bản thân
- Hiển thị **trạng thái** của yêu cầu
- Cho phép **xóa yêu cầu** nếu ở trạng thái "đang chờ"

##### **Tab 3: Cài đặt (Thông tin tài khoản)**
- Hiển thị ảnh đại diện và thông tin cá nhân
- Hiển thị badge **"Quản trị viên"** nếu có quyền admin
- Các tùy chọn:
  - Đổi mật khẩu
  - Chỉnh sửa thông tin
  - Đăng xuất

---

## 4. Tính năng chung cho cả admin và người dùng

- **Nút SOS khẩn cấp**:
  - Nút màu đỏ ở góc dưới màn hình
  - Khi nhấn, hiển thị thông báo đã gửi yêu cầu cứu trợ khẩn cấp

- **Xử lý đăng xuất:**
  - Hiển thị hộp thoại xác nhận
  - Cập nhật `isLoggedIn = false` trong Firestore
  - Đặt lại các biến trạng thái: `userData`, `isLoggedIn`, `isActuallyAdmin`

---

## 5. Xử lý trạng thái không đăng nhập

- Khi chưa đăng nhập:
  - Các tab yêu cầu quyền sẽ hiển thị **thông báo** và nút **"Đăng nhập ngay"**
  - Nút **đăng nhập** được hiển thị thay thế nút đăng xuất trên thanh tiêu đề
  - Khi nhấn đăng nhập:
    - Chuyển đến màn hình `DangNhap`
    - Cập nhật lại dữ liệu sau khi đăng nhập thành công


