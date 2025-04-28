import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/evacuation_area.dart';
import '../../services/evacuation_service.dart';
import 'evacuation_area_map_view.dart';

class EvacuationAreasListUser extends StatefulWidget {
  @override
  _EvacuationAreasListUserState createState() => _EvacuationAreasListUserState();
}

class _EvacuationAreasListUserState extends State<EvacuationAreasListUser> {
  final EvacuationService _evacuationService = EvacuationService();
  final TextEditingController _searchController = TextEditingController();
  List<EvacuationArea> _filteredAreas = [];
  String _searchText = "";
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
    });
  }
  
  List<EvacuationArea> _filterAreas(List<EvacuationArea> areas) {
    if (_searchText.isEmpty) {
      return areas;
    }
    
    return areas.where((area) {
      final nameLower = area.name.toLowerCase();
      final addressLower = area.address.toLowerCase();
      final searchLower = _searchText.toLowerCase();
      
      return nameLower.contains(searchLower) || 
             addressLower.contains(searchLower);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khu vực di tản...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              ),
            ),
          ),
          
          // Danh sách khu vực
          Expanded(
            child: StreamBuilder<List<EvacuationArea>>(
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
                          'Chưa có khu vực di tản nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                // Lọc danh sách khu vực theo từ khóa tìm kiếm
                _filteredAreas = _filterAreas(snapshot.data!);
                
                if (_filteredAreas.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy khu vực di tản phù hợp',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _filteredAreas.length,
                  itemBuilder: (context, index) {
                    final area = _filteredAreas[index];
                    return _buildEvacuationAreaCard(area);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvacuationAreaCard(EvacuationArea area) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showAreaDetails(area);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home_work,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                area.address,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[300]),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Sức chứa: ${area.capacity} người',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: area.status == 'active' ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      area.status == 'active' ? 'Đang hoạt động' : 'Tạm dừng',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Chi tiết'),
                    onPressed: () {
                      _showAreaDetails(area);
                    },
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.map, color: Colors.white, size: 18),
                    label: Text('Xem bản đồ', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvacuationAreaMapView(area: area),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAreaDetails(EvacuationArea area) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với nút đóng
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.home_work, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chi tiết khu vực di tản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Nội dung chi tiết
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    _infoRow(Icons.location_on, 'Địa chỉ', area.address),
                    _infoRow(Icons.people, 'Sức chứa', '${area.capacity} người'),
                    _infoRow(Icons.circle, 'Trạng thái', 
                      area.status == 'active' ? 'Đang hoạt động' : 'Tạm dừng',
                      color: area.status == 'active' ? Colors.green : Colors.grey
                    ),
                    
                    if (area.description.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        area.description,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                    
                    SizedBox(height: 24),
                    Text(
                      'Vị trí trên bản đồ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Stack(
                          children: [
                            Image.network(
                              'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-s+ff0000(${area.longitude},${area.latitude})/${area.longitude},${area.latitude},14,0/400x180?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4M29iazA2Z2gycXA4N2pmbDZmangifQ.-g_vE53SD2WrJ6tFX7QHmA',
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.map, color: Colors.white, size: 16),
                                label: Text('Xem đầy đủ', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EvacuationAreaMapView(area: area),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Nút chỉ đường
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Chỉ đường đến đây',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  _openDirections(area);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[700]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lọc khu vực di tản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tất cả khu vực'),
              leading: Icon(Icons.all_inclusive),
              onTap: () {
                Navigator.pop(context);
                // Không cần lọc
              },
            ),
            ListTile(
              title: Text('Đang hoạt động'),
              leading: Icon(Icons.check_circle, color: Colors.green),
              onTap: () {
                Navigator.pop(context);
                // Lọc theo trạng thái active
              },
            ),
            ListTile(
              title: Text('Sức chứa cao nhất'),
              leading: Icon(Icons.people),
              onTap: () {
                Navigator.pop(context);
                // Sắp xếp theo sức chứa
              },
            ),
            ListTile(
              title: Text('Gần đây nhất'),
              leading: Icon(Icons.near_me),
              onTap: () {
                Navigator.pop(context);
                // Sắp xếp theo khoảng cách
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  void _openDirections(EvacuationArea area) {
    // Mở trang bản đồ toàn màn hình với chế độ chỉ đường
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvacuationAreaMapView(
          area: area,
          showDirections: true,
        ),
      ),
    );
  }
}