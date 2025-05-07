import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/nhanvien.dart';
import '../../../../services/nhanvien_service.dart';
import 'them_moi.dart'; // Import trang thêm mới nhân viên

class NhanVienListTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const NhanVienListTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  State<NhanVienListTab> createState() => _NhanVienListTabState();
}

class _NhanVienListTabState extends State<NhanVienListTab> {
  final NhanVienService _nhanVienService = NhanVienService();
  
  // Chuyển sang trang thêm mới nhân viên
  void _navigateToAddNewEmployee() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThemMoiNhanVienPage(
          onNhanVienAdded: () {
            // khi thêm nhân viên thành công
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Thêm nhân viên thành công'))
            );
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh sách nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<NhanVien>>(
        // Sử dụng stream để lấy danh sách nhân viên đã sắp xếp theo tên
        stream: _nhanVienService.getNhanVienList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Không có dữ liệu nhân viên'));
          }

          List<NhanVien> nhanVienList = snapshot.data!;
          
          return ListView.builder(
            itemCount: nhanVienList.length,
            padding: EdgeInsets.all(8),
            itemBuilder: (context, index) {
              NhanVien nv = nhanVienList[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with employee name and ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nv.hoTen,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Mã: ${nv.maNhanVien}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      Divider(height: 24),
                      
                      // Employee information rows
                      _buildInfoRow('Ngày sinh', DateFormat('dd/MM/yyyy').format(nv.ngaySinh)),
                      _buildInfoRow('Giới tính', nv.gioiTinh),
                      _buildInfoRow('Chức vụ', nv.chucVu),
                      _buildInfoRow('Hệ số lương', nv.heSoLuong.toString()),
                      _buildInfoRow('Lương cơ bản', currencyFormat.format(nv.luongCoBan)),
                      
                      Divider(height: 24),
                      
                      
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddNewEmployee,
        icon: Icon(Icons.add),
        label: Text('Thêm nhân viên'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // Widget hiển thị từng dòng thông tin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}