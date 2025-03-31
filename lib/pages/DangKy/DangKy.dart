import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../DangNhap/DangNhap.dart';

class Dangky extends StatefulWidget {
  @override
  _DangKy createState() => _DangKy();
}

class _DangKy extends State<Dangky> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> dangky() async {
    print("Bắt đầu quá trình đăng ký");

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("Đang kiểm tra số điện thoại: ${phoneController.text.trim()}");

      var user = await firestore
          .collection('users')
          .where("phone", isEqualTo: phoneController.text.trim())
          .get();

      print("Kết quả kiểm tra: ${user.docs.length} documents");

      if (user.docs.isNotEmpty) {
        if (!mounted) return; // Kiểm tra widget còn mounted không
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Số điện thoại đã được đăng ký')));
        
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      print("Đang thêm người dùng mới");
      
      // Sử dụng await thay vì then() để dễ xử lý
      try {
        DocumentReference docRef = await firestore.collection('users').add({
          'phone': phoneController.text.trim(),
          'password': passwordController.text.trim(),
          'name': nameController.text.trim(),
          'created_at': Timestamp.now(),
        });
        
        print("Thêm người dùng mới thành công: ${docRef.id}");
        
        // Kiểm tra widget còn mounted không trước khi truy cập context
        if (!mounted) return;
        
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đăng ký thành công')));
        
        // Đợi một lúc để người dùng xem thông báo
        await Future.delayed(Duration(seconds: 1));
        
        // Kiểm tra lại widget còn mounted không sau khi delay
        if (!mounted) return;
        
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Dangnhap()));
      } catch (e) {
        print("❌ Lỗi khi thêm người dùng mới: $e");
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        throw e; // Re-throw nếu cần xử lý ở ngoài
      }
      
      // Lưu ý: Không thêm code xử lý thành công ở đây
      // Vì đã xử lý trong khối try bên trong
      
    } catch (e) {
      print("❌ Lỗi khi đăng ký: $e");

      String errorMessage = "Đã xảy ra lỗi trong quá trình đăng ký.";

      if (e.toString().contains("unavailable")) {
        errorMessage =
            "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.";
      } else if (e.toString().contains("permission-denied")) {
        errorMessage = "Không có quyền thực hiện thao tác này.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký tài khoản'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 20),
                  Icon(
                    Icons.app_registration,
                    size: 70,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  // Trường nhập tên
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      hintText: 'Nhập họ tên của bạn',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Trường nhập số điện thoại
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại của bạn',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (value.length < 10) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Trường nhập mật khẩu
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu của bạn',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Trường xác nhận mật khẩu
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      hintText: 'Nhập lại mật khẩu của bạn',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  // Nút đăng ký
                  ElevatedButton(
                    onPressed: isLoading ? null : dangky,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'ĐĂNG KÝ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  SizedBox(height: 20),
                  // Link quay lại đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Đã có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          )),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
