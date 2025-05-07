import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/nguoi.dart';
import '../../../../services/nguoi_service.dart';

class NguoiListTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const NguoiListTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  State<NguoiListTab> createState() => _NguoiListTabState();
}

class _NguoiListTabState extends State<NguoiListTab> {
  final NguoiService _nguoiService = NguoiService();
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _diemController = TextEditingController();
  String _gioiTinh = 'Nam'; // Mặc định là Nam
  String _timKiem = ''; // Lưu từ khóa tìm kiếm
  double _locDiem = 0; // Mặc định không lọc theo điểm
  final TextEditingController _searchController = TextEditingController(); // Controller cho ô tìm kiếm
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _timKiem = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _tenController.dispose();
    _diemController.dispose();
    super.dispose();
  }

  // Hiển thị dialog để chọn lọc theo điểm
  void _showDiemFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lọc theo điểm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tất cả'),
                onTap: () {
                  setState(() {
                    _locDiem = 0;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Điểm > 8'),
                onTap: () {
                  setState(() {
                    _locDiem = 8;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Điểm > 9'),
                onTap: () {
                  setState(() {
                    _locDiem = 9;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Hiển thị dialog để thêm người mới
  void _showAddNguoiDialog() {
    _tenController.clear();
    _diemController.clear();
    _gioiTinh = 'Nam';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm người mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tenController,
                  decoration: InputDecoration(
                    labelText: 'Tên',
                    hintText: 'Nhập tên',
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _gioiTinh,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                  ),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _gioiTinh = newValue;
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _diemController,
                  decoration: InputDecoration(
                    labelText: 'Điểm',
                    hintText: 'Nhập điểm',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                // Kiểm tra dữ liệu nhập vào
                if (_tenController.text.isEmpty || _diemController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                  );
                  return;
                }

                try {
                  double diem = double.parse(_diemController.text);
                  Nguoi nguoiMoi = Nguoi(
                    id: '', // ID sẽ được tạo tự động bởi Firestore
                    ten: _tenController.text.trim(),
                    gioiTinh: _gioiTinh,
                    diem: diem,
                  );

                  await _nguoiService.addNguoi(nguoiMoi);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm người mới thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách người'),
        centerTitle: true,
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Phần tìm kiếm và lọc
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Ô tìm kiếm
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên...',
                    // prefixIcon: Icon(Icons.search),
                    // border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(10.0),
                    // ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _timKiem.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Nút lọc theo điểm
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showDiemFilterDialog,
                      // icon: Icon(Icons.filter_list),
                      label: Text(_locDiem > 0 ? 'Điểm > ${_locDiem}' : 'Lọc theo điểm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locDiem > 0 
                            ? Theme.of(context).colorScheme.primary 
                            : null,
                        foregroundColor: _locDiem > 0 
                            ? Colors.white 
                            : null,
                      ),
                    ),
                    // if (_locDiem > 0)
                    //   Padding(
                    //     padding: const EdgeInsets.only(left: 8.0),
                    //     child: TextButton(
                    //       onPressed: () {
                    //         setState(() {
                    //           _locDiem = 0;
                    //         });
                    //       },
                    //       child: Text('Xóa bộ lọc'),
                    //     ),
                    //   ),
                  ],
                ),
              ],
            ),
          ),
          
          // Phần hiển thị danh sách
          Expanded(
            child: StreamBuilder<List<Nguoi>>(
              stream: _nguoiService.getNguoiList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Không có dữ liệu'));
                }

                // Lọc danh sách người theo tên và điểm
                List<Nguoi> nguoiList = snapshot.data!
                    .where((nguoi) => 
                        nguoi.ten.toLowerCase().contains(_timKiem.toLowerCase()) && 
                        (_locDiem <= 0 || nguoi.diem > _locDiem)
                    )
                    .toList();
                
                if (nguoiList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy kết quả nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: nguoiList.length,
                  itemBuilder: (context, index) {
                    Nguoi nguoi = nguoiList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          'Tên: ${nguoi.ten}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Giới tính: ${nguoi.gioiTinh}'),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Text(
                            'Điểm: ${nguoi.diem.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              // color: nguoi.diem >= 8 ? Colors.green[800] : 
                              //        nguoi.diem >= 5 ? Colors.blue[800] : Colors.red[800],
                            ),
                          ),
                        ),
                        onTap: () {
                          _showEditNguoiDialog(nguoi);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNguoiDialog,
        child: Icon(Icons.add),
        tooltip: 'Thêm người mới',
      ),
    );

  }
  
  void _showEditNguoiDialog(Nguoi nguoi) {
    _tenController.text = nguoi.ten;
    _diemController.text = nguoi.diem.toString();
    _gioiTinh = nguoi.gioiTinh;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tenController,
                  decoration: InputDecoration(
                    labelText: 'Tên',
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _gioiTinh,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                  ),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _gioiTinh = newValue;
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _diemController,
                  decoration: InputDecoration(
                    labelText: 'Điểm',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  double diem = double.parse(_diemController.text);
                  Nguoi updatedNguoi = Nguoi(
                    id: nguoi.id,
                    ten: _tenController.text.trim(),
                    gioiTinh: _gioiTinh,
                    diem: diem,
                  );

                  await _nguoiService.updateNguoi(nguoi.id, updatedNguoi);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: Text('Lưu'),
            ),
            TextButton(
              onPressed: () async {
                // Hiển thị dialog xác nhận xóa
                bool confirm = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Xác nhận xóa'),
                      content: Text('Bạn có chắc chắn muốn xóa ${nguoi.ten}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Xóa'),
                        ),
                      ],
                    );
                  },
                ) ?? false;
                
                if (confirm) {
                  try {
                    await _nguoiService.deleteNguoi(nguoi.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa ${nguoi.ten}')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa: $e')),
                    );
                  }
                }
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


}