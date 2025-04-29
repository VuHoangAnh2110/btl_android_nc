import 'package:flutter/material.dart';
import '../../../../services/evacuation_service.dart';
import '../../../../models/evacuation_area.dart';
import '../../../EvacuationArea/add_evacuation_area.dart';

class AdminEvacuationAreasTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoggedIn;

  const AdminEvacuationAreasTab({
    Key? key,
    required this.userData,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _AdminEvacuationAreasTabState createState() => _AdminEvacuationAreasTabState();
}

class _AdminEvacuationAreasTabState extends State<AdminEvacuationAreasTab> {
  final EvacuationService _evacuationService = EvacuationService();

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return _buildLoginRequired();
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildEvacuationAreasList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEvacuationArea()),
          ).then((_) {
            // Refresh data when returning from add screen
            setState(() {});
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Thêm khu vực di tản',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Đặt vị trí nút thêm ở góc dưới bên trái
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vui lòng đăng nhập để quản lý khu vực di tản',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dangnhap');
            },
            child: Text('Đăng nhập'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý khu vực di tản',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Thêm, chỉnh sửa hoặc xóa các khu vực di tản để người dùng có thể tìm nơi an toàn khi cần thiết',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvacuationAreasList() {
    return StreamBuilder<List<EvacuationArea>>(
      stream: _evacuationService.getEvacuationAreas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có khu vực di tản nào được thiết lập',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhấn vào nút + để thêm khu vực di tản mới',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final areas = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final area = areas[index];
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  area.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Expanded(child: Text(area.address)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Sức chứa: ${area.capacity} người'),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: area.status == 'active' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    area.status == 'active' ? 'Hoạt động' : 'Tạm dừng',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                onTap: () {
                  _showOptionsDialog(area);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showOptionsDialog(EvacuationArea area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Khu vực di tản: ${area.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Địa chỉ: ${area.address}'),
            SizedBox(height: 8),
            Text('Sức chứa: ${area.capacity} người'),
            SizedBox(height: 8),
            Text('Trạng thái: ${area.status == 'active' ? 'Đang hoạt động' : 'Tạm dừng'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(area);
            },
            child: Text('Chỉnh sửa'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(area);
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(EvacuationArea area) {
    // Tạo các controller và gán giá trị ban đầu
    final nameController = TextEditingController(text: area.name);
    final capacityController = TextEditingController(text: area.capacity.toString());
    var statusValue = area.status == 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Chỉnh sửa khu vực di tản'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên khu vực',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    decoration: InputDecoration(
                      labelText: 'Sức chứa',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Trạng thái:'),
                      SizedBox(width: 16),
                      Switch(
                        value: statusValue,
                        onChanged: (value) {
                          setState(() => statusValue = value);
                        },
                      ),
                      Text(statusValue ? 'Hoạt động' : 'Tạm dừng'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final updatedArea = EvacuationArea(
                    id: area.id,
                    name: nameController.text.trim(),
                    address: area.address,
                    description: area.description,
                    latitude: area.latitude,
                    longitude: area.longitude,
                    capacity: int.tryParse(capacityController.text) ?? area.capacity,
                    status: statusValue ? 'active' : 'inactive',
                    createdAt: area.createdAt,
                  );

                  _evacuationService.updateEvacuationArea(area.id, updatedArea)
                    .then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật khu vực di tản')),
                      );
                    })
                    .catchError((error) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $error')),
                      );
                    });
                },
                child: Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(EvacuationArea area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa khu vực di tản'),
        content: Text('Bạn có chắc chắn muốn xóa khu vực "${area.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _evacuationService.deleteEvacuationArea(area.id)
                .then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xóa khu vực di tản')),
                  );
                })
                .catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $error')),
                  );
                });
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}