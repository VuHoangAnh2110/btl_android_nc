import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/nhanvien.dart';
import '../../../../services/nhanvien_service.dart';

class ThemMoiNhanVienPage extends StatefulWidget {
  final Function() onNhanVienAdded;

  const ThemMoiNhanVienPage({
    Key? key, 
    required this.onNhanVienAdded,
  }) : super(key: key);

  @override
  State<ThemMoiNhanVienPage> createState() => _ThemMoiNhanVienPageState();
}

class _ThemMoiNhanVienPageState extends State<ThemMoiNhanVienPage> {
  final _formKey = GlobalKey<FormState>();
  final NhanVienService _nhanVienService = NhanVienService();
  
  // Controllers cho form
  final TextEditingController _maNVController = TextEditingController();
  final TextEditingController _hoTenController = TextEditingController();
  final TextEditingController _chucVuController = TextEditingController();
  final TextEditingController _heSoLuongController = TextEditingController();
  final TextEditingController _luongCoBanController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedGioiTinh = 'Nam';
  bool _isLoading = false;
  
  @override
  void dispose() {
    _maNVController.dispose();
    _hoTenController.dispose();
    _chucVuController.dispose();
    _heSoLuongController.dispose();
    _luongCoBanController.dispose();
    super.dispose();
  }

  // Hiển thị date picker để chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Kiểm tra mã nhân viên đã tồn tại chưa
        bool exists = await _nhanVienService.isMaNhanVienExists(_maNVController.text);
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mã nhân viên đã tồn tại'))
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        double heSoLuong = double.parse(_heSoLuongController.text);
        double luongCoBan = double.parse(_luongCoBanController.text);
        
        NhanVien nhanVienMoi = NhanVien(
          id: '',
          maNhanVien: _maNVController.text.trim(),
          hoTen: _hoTenController.text.trim(),
          ngaySinh: _selectedDate,
          gioiTinh: _selectedGioiTinh,
          chucVu: _chucVuController.text.trim(),
          heSoLuong: heSoLuong,
          luongCoBan: luongCoBan,
        );

        await _nhanVienService.addNhanVien(nhanVienMoi);
        widget.onNhanVienAdded();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'))
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm nhân viên mới'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mã nhân viên
                    TextFormField(
                      controller: _maNVController,
                      decoration: InputDecoration(
                        labelText: 'Mã nhân viên *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã nhân viên';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Họ tên
                    TextFormField(
                      controller: _hoTenController,
                      decoration: InputDecoration(
                        labelText: 'Họ tên *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Ngày sinh
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Ngày sinh',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Giới tính
                    DropdownButtonFormField<String>(
                      value: _selectedGioiTinh,
                      decoration: InputDecoration(
                        labelText: 'Giới tính',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: ['Nam', 'Nữ'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedGioiTinh = newValue;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Chức vụ
                    TextFormField(
                      controller: _chucVuController,
                      decoration: InputDecoration(
                        labelText: 'Chức vụ *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập chức vụ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Hệ số lương
                    TextFormField(
                      controller: _heSoLuongController,
                      decoration: InputDecoration(
                        labelText: 'Hệ số lương *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập hệ số lương';
                        }
                        try {
                          double val = double.parse(value);
                          if (val <= 0) {
                            return 'Hệ số lương phải lớn hơn 0';
                          }
                        } catch (e) {
                          return 'Hệ số lương không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Lương cơ bản
                    TextFormField(
                      controller: _luongCoBanController,
                      decoration: InputDecoration(
                        labelText: 'Lương cơ bản *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập lương cơ bản';
                        }
                        try {
                          double val = double.parse(value);
                          if (val <= 0) {
                            return 'Lương cơ bản phải lớn hơn 0';
                          }
                        } catch (e) {
                          return 'Lương cơ bản không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Nút lưu
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(Icons.save),
                      label: Text('Lưu nhân viên', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}