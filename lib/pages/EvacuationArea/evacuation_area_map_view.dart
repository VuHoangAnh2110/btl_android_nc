import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evacuation_area.dart';
import '../../services/goong_map_service.dart';
import 'dart:math' as math;
import 'dart:async';

class EvacuationAreaMapView extends StatefulWidget {
  final EvacuationArea area;
  final bool showDirections;

  const EvacuationAreaMapView({
    Key? key,
    required this.area,
    this.showDirections = false,
  }) : super(key: key);

  @override
  _EvacuationAreaMapViewState createState() => _EvacuationAreaMapViewState();
}

class _EvacuationAreaMapViewState extends State<EvacuationAreaMapView> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _showDirections = false;
  List<LatLng> _routePoints = [];
  String _distanceText = "";
  String _durationText = "";
  bool _isNavigating = false; // Đang trong chế độ chỉ đường
  double _heading = 0.0; // Hướng hiện tại của người dùng (góc tính theo độ)
  StreamSubscription<Position>? _positionStreamSubscription;
  // Thêm biến này để lưu lại chỉ dẫn hiện tại
  String _currentInstruction = "Đang chuẩn bị chỉ đường...";
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _showDirections = widget.showDirections;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      _mapController.move(LatLng(widget.area.latitude, widget.area.longitude), 14);
      
      if (_showDirections && _currentLocation != null) {
        _getDirections();
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getDirections() async {
    if (_currentLocation == null) return;
    
    setState(() {
      _isLoading = true;
      _routePoints = []; // Reset đường đi cũ
    });
    
    try {
      final result = await GoongMapService.getDirections(
        _currentLocation!.latitude, 
        _currentLocation!.longitude,
        widget.area.latitude,
        widget.area.longitude
      );
      
      if (result != null) {
        // Kiểm tra nếu result['points'] tồn tại và có thể cast thành List<LatLng>
        if (result.containsKey('points')) {
          try {
            final List<dynamic> pointsData = result['points'] as List<dynamic>;
            final List<LatLng> points = pointsData.map((point) {
              if (point is LatLng) return point;
              return LatLng(0, 0); // Fallback nếu không phải LatLng
            }).toList();
            
            setState(() {
              _routePoints = points;
              _distanceText = result['distance'] ?? 'Không xác định';
              _durationText = result['duration'] ?? 'Không xác định';
            });
            
            // Sau khi có đường đi, tự động zoom để hiển thị toàn bộ đường đi
            if (_routePoints.isNotEmpty) {
              _fitBounds();
            }
          } catch (e) {
            print("Lỗi xử lý dữ liệu points: $e");
            setState(() {
              // Fallback: tạo đường thẳng từ vị trí hiện tại đến điểm đích
              _routePoints = [
                _currentLocation!,
                LatLng(widget.area.latitude, widget.area.longitude)
              ];
              _distanceText = result['distance'] ?? 'Không xác định';
              _durationText = result['duration'] ?? 'Không xác định';
            });
            _fitBounds();
          }
        } else {
          throw Exception('Dữ liệu directions không có trường points');
        }
      } else {
        throw Exception('Không nhận được dữ liệu directions');
      }
    } catch (e) {
      print("Error getting directions: $e");
      
      // Fallback: luôn hiển thị ít nhất đường thẳng giữa 2 điểm
      setState(() {
        _routePoints = [
          _currentLocation!,
          LatLng(widget.area.latitude, widget.area.longitude)
        ];
        _distanceText = 'Không xác định';
        _durationText = 'Không xác định';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải chi tiết chỉ đường, hiển thị đường thẳng'),
          duration: Duration(seconds: 3),
        )
      );
      
      _fitBounds();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleDirections() {
    setState(() {
      _showDirections = !_showDirections;
    });
    
    if (_showDirections && _currentLocation != null && _routePoints.isEmpty) {
      _getDirections();
    }
  }
  
  void _openInMaps() async {
    try {
      final url = "https://www.google.com/maps/dir/?api=1&destination=${widget.area.latitude},${widget.area.longitude}&travelmode=driving";
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở ứng dụng bản đồ'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi mở bản đồ: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.area.name, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showDirections ? Icons.directions_off : Icons.directions),
            onPressed: _toggleDirections,
            tooltip: _showDirections ? 'Tắt chỉ đường' : 'Bật chỉ đường',
          ),
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: _openInMaps,
            tooltip: 'Mở trong Google Maps',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.area.latitude, widget.area.longitude),
              initialZoom: 14.0,
              // Thêm thuộc tính này để đảm bảo xoay đúng cách
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all, // Cho phép xoay bản đồ
                rotationThreshold: 0.01, 
              ),
              keepAlive: true, // Giữ bản đồ khi không hiển thị
              onMapReady: () {
                if (_showDirections && _currentLocation != null) {
                  if (_routePoints.isNotEmpty) {
                    _fitBounds();
                  }
                }
              },
            ),
            children: [
              TileLayer(
                // Thay đổi style bản đồ tùy theo chế độ
                urlTemplate: _isNavigating 
                  ? 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=SZiHm8nz31ezgVgMdqrO'
                  : 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=SZiHm8nz31ezgVgMdqrO',
                userAgentPackageName: 'com.example.app',
              ),
              
              // Hiển thị đường đi nếu có dữ liệu và chọn chế độ chỉ đường
              if (_showDirections && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              
              // Marker cho vị trí người dùng
              MarkerLayer(
                markers: [
                  // Marker khu vực di tản
                  Marker(
                    width: 100, // Thêm width để đảm bảo đủ chỗ cho nội dung
                    height: 70, // Thêm height để đảm bảo đủ chỗ cho nội dung
                    point: LatLng(widget.area.latitude, widget.area.longitude),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none, // Cho phép vượt ra ngoài giới hạn
                      children: [
                        // Icon marker
                        Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                        // Nhãn ở trên marker
                        Positioned(
                          bottom: 35, // Đẩy nhãn lên trên
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'Khu vực di tản',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Marker vị trí hiện tại nếu có
                  if (_currentLocation != null)
                    Marker(
                      width: 60,
                      height: 60,
                      point: _currentLocation!,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        child: Transform.rotate(
                          angle: _isNavigating ? (_heading * (math.pi / 180)) : 0,
                          child: Stack(
                            children: [
                              // Marker khi không định hướng (chấm tròn)
                              if (!_isNavigating)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                                
                              // Marker khi định hướng (mũi tên)
                              if (_isNavigating)
                                Icon(
                                  Icons.navigation,
                                  color: Colors.blue,
                                  size: 30,
                                  // Đảm bảo icon luôn hướng theo hướng di chuyển
                                  shadows: [
                                    Shadow(
                                      color: Colors.white,
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
            
          // Hiển thị thông tin chỉ đường
          if (_showDirections && _routePoints.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hướng dẫn chỉ đường',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.directions, color: Colors.blue),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khoảng cách: $_distanceText'),
                              Text('Thời gian: $_durationText'),
                              // Hiển thị chỉ dẫn hiện tại
                              Text('Chỉ dẫn: $_currentInstruction'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8, // Khoảng cách giữa các widget
                        runSpacing: 8, // Khoảng cách giữa các hàng (nếu wrap)
                        children: [
                          if (!_isNavigating)
                            ElevatedButton.icon(
                              icon: Icon(Icons.navigation, color: Colors.white, size: 16), // Giảm kích thước icon
                              label: Text('Bắt đầu đi', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Giảm padding
                              ),
                              onPressed: _startNavigation,
                            )
                          else
                            ElevatedButton.icon(
                              icon: Icon(Icons.stop, color: Colors.white, size: 16), // Giảm kích thước icon
                              label: Text('Dừng', style: TextStyle(color: Colors.white)), // Rút gọn text
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Giảm padding
                              ),
                              onPressed: _stopNavigation,
                            ),
                          OutlinedButton.icon(
                            icon: Icon(Icons.directions, size: 16), // Giảm kích thước icon
                            label: Text('Google Maps'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Giảm padding
                            ),
                            onPressed: _openInMaps,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          // Hiển thị chỉ dẫn khi đang điều hướng
          if (_isNavigating)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getDirectionIcon(_currentInstruction),
                      color: Colors.blue,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentInstruction,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _distanceText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          _mapController.move(LatLng(widget.area.latitude, widget.area.longitude), 15);
        },
        child: Icon(Icons.center_focus_strong),
        tooltip: 'Tập trung vào khu vực di tản',
      ),
    );
  }
  
  void _fitBounds() {
    if (_currentLocation == null) return;
    
    try {
      // Nếu có route points, dùng toàn bộ các điểm để tính bounds
      if (_routePoints.isNotEmpty) {
        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        
        // Tính bounds từ tất cả các điểm trên route
        for (var point in _routePoints) {
          minLat = math.min(minLat, point.latitude);
          maxLat = math.max(maxLat, point.latitude);
          minLng = math.min(minLng, point.longitude);
          maxLng = math.max(maxLng, point.longitude);
        }
        
        // Thêm padding
        double latPadding = (maxLat - minLat) * 0.2;
        double lngPadding = (maxLng - minLng) * 0.2;
        
        minLat -= latPadding;
        maxLat += latPadding;
        minLng -= lngPadding;
        maxLng += lngPadding;
        
        // Tính center
        double centerLat = (minLat + maxLat) / 2;
        double centerLng = (minLng + maxLng) / 2;
        
        // Tính zoom phù hợp
        double zoom = 12.0;
        
        _mapController.move(LatLng(centerLat, centerLng), zoom);
      } else {
        // Nếu không có route points, chỉ hiển thị vị trí người dùng và điểm đến
        double minLat = math.min(_currentLocation!.latitude, widget.area.latitude);
        double maxLat = math.max(_currentLocation!.latitude, widget.area.latitude);
        double minLng = math.min(_currentLocation!.longitude, widget.area.longitude);
        double maxLng = math.max(_currentLocation!.longitude, widget.area.longitude);
        
        // Thêm padding
        double latPadding = (maxLat - minLat) * 0.3;
        double lngPadding = (maxLng - minLng) * 0.3;
        
        // Tính center
        double centerLat = (minLat + maxLat) / 2;
        double centerLng = (minLng + maxLng) / 2;
        
        _mapController.move(LatLng(centerLat, centerLng), 13);
      }
    } catch (e) {
      print("Error fitting bounds: $e");
      // Nếu có lỗi, sử dụng zoom mặc định
      _mapController.move(LatLng(widget.area.latitude, widget.area.longitude), 14);
    }
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
    });
    
    // Reset góc xoay trước khi bắt đầu
    _mapController.rotate(0);
    
    // Bắt đầu lắng nghe vị trí người dùng với tần suất cao hơn
    _startLocationUpdates();
    
    // Zoom đến vị trí người dùng
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 18);
    }
    
    // Thông báo cho người dùng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bắt đầu chỉ đường. Hãy di chuyển theo đường màu xanh!'),
        duration: Duration(seconds: 3),
      )
    );
  }

  void _stopNavigation() {
    // Hủy đăng ký lắng nghe vị trí
    _positionStreamSubscription?.cancel();
    
    setState(() {
      _isNavigating = false;
      // Đặt lại hướng về 0
      _heading = 0.0;
    });
    
    // Di chuyển bản đồ về chế độ mặc định
    _mapController.rotate(0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã dừng chỉ đường'),
        duration: Duration(seconds: 2),
      )
    );
  }

  void _startLocationUpdates() {
    // Hủy subscription cũ nếu có
    _positionStreamSubscription?.cancel();
    
    // Đăng ký lắng nghe vị trí với tần suất cao (mỗi 1-3 giây và khoảng cách 5-10 mét)
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Cập nhật mỗi khi di chuyển 5m
        intervalDuration: Duration(seconds: 1),
      ),
    ).listen((Position position) {
      // Cập nhật vị trí hiện tại
      final newLocation = LatLng(position.latitude, position.longitude);
      
      // Kiểm tra và cập nhật heading
      if (position.heading != null && position.heading! > 0) {
        // Chỉ cập nhật heading khi có giá trị hợp lệ (>0)
        setState(() {
          _currentLocation = newLocation;
          _heading = position.heading!;
        });
        
        // Chỉ xoay bản đồ khi đang trong chế độ điều hướng
        if (_isNavigating) {
          try {
            // Đảm bảo góc xoay hợp lệ
            _mapController.rotate(_heading);
          } catch (e) {
            print("Lỗi khi xoay bản đồ: $e");
          }
          
          // Cập nhật góc nhìn bản đồ để luôn theo dõi người dùng
          _mapController.move(newLocation, 18); // Zoom cao hơn cho chế độ chỉ đường
        }
      } else {
        // Nếu không có heading, chỉ cập nhật vị trí
        setState(() {
          _currentLocation = newLocation;
        });
        
        if (_isNavigating) {
          _mapController.move(newLocation, 18);
        }
      }
      
      // Kiểm tra nếu đã đến nơi (trong phạm vi 20m)
      double distanceToDestination = Geolocator.distanceBetween(
        position.latitude, 
        position.longitude,
        widget.area.latitude,
        widget.area.longitude
      );
      
      if (distanceToDestination <= 20) {
        // Đã đến nơi
        _showArrivalNotification();
        _stopNavigation();
      }
      
      // Cập nhật chỉ dẫn
      _updateNavigationInstruction(newLocation);
      
      // Cập nhật hướng dẫn chỉ đường
      if (_isNavigating && _routePoints.isNotEmpty) {
        _updateNavigationInstruction(_currentLocation!);
      }
    });
  }

  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Bạn đã đến khu vực di tản!', style: TextStyle(color: Colors.white)),
          ],
        ),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      )
    );
  }

  // Thêm hàm này để lấy chỉ dẫn dựa trên vị trí hiện tại
  void _updateNavigationInstruction(LatLng currentPos) {
    if (_routePoints.isEmpty || !_isNavigating) return;
    
    // Tìm đoạn đường gần nhất với vị trí hiện tại
    int closestSegmentIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < _routePoints.length - 1; i++) {
      double dist = _distanceToSegment(
        currentPos, 
        _routePoints[i], 
        _routePoints[i + 1]
      );
      
      if (dist < minDistance) {
        minDistance = dist;
        closestSegmentIndex = i;
      }
    }
    
    // Kiểm tra nếu đã gần đến điểm cuối
    if (closestSegmentIndex >= _routePoints.length - 2) {
      setState(() {
        _currentInstruction = "Đã gần đến nơi, tiếp tục đi thẳng";
      });
      return;
    }
    
    // Tính góc giữa đoạn đường hiện tại và đoạn tiếp theo
    LatLng p1 = _routePoints[closestSegmentIndex];
    LatLng p2 = _routePoints[closestSegmentIndex + 1];
    LatLng p3 = _routePoints[closestSegmentIndex + 2];
    
    double angle = _calculateAngle(p1, p2, p3);
    
    // Xác định hướng rẽ dựa vào góc
    String direction = "";
    if (angle > 30) {
      direction = "Rẽ phải";
    } else if (angle < -30) {
      direction = "Rẽ trái";
    } else if (angle > 10) {
      direction = "Đi nhẹ sang phải";
    } else if (angle < -10) {
      direction = "Đi nhẹ sang trái";
    } else {
      direction = "Đi thẳng";
    }
    
    setState(() {
      _currentInstruction = direction;
    });
  }

  // Tính khoảng cách từ một điểm đến đoạn thẳng
  double _distanceToSegment(LatLng p, LatLng v, LatLng w) {
    double l2 = _sqrDist(v, w);
    if (l2 == 0) return _haversineDistance(p, v);
    
    double t = ((p.longitude - v.longitude) * (w.longitude - v.longitude) +
                (p.latitude - v.latitude) * (w.latitude - v.latitude)) / l2;
                
    t = math.max(0, math.min(1, t));
    
    LatLng projection = LatLng(
      v.latitude + t * (w.latitude - v.latitude),
      v.longitude + t * (w.longitude - v.longitude)
    );
    
    return _haversineDistance(p, projection);
  }

  double _sqrDist(LatLng v, LatLng w) {
    return math.pow(v.longitude - w.longitude, 2) + math.pow(v.latitude - w.latitude, 2).toDouble();
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    // Tính khoảng cách theo công thức haversine
    const double R = 6371000; // Bán kính Trái Đất tính bằng mét
    double phi1 = p1.latitude * math.pi / 180;
    double phi2 = p2.latitude * math.pi / 180;
    double deltaPhi = (p2.latitude - p1.latitude) * math.pi / 180;
    double deltaLambda = (p2.longitude - p1.longitude) * math.pi / 180;

    double a = math.sin(deltaPhi/2) * math.sin(deltaPhi/2) +
            math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda/2) * math.sin(deltaLambda/2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));

    return R * c;
  }

  // Tính góc giữa ba điểm (để xác định hướng rẽ)
  double _calculateAngle(LatLng p1, LatLng p2, LatLng p3) {
    double bearing1 = _calculateBearing(p1, p2);
    double bearing2 = _calculateBearing(p2, p3);
    
    double angle = bearing2 - bearing1;
    
    // Chuẩn hóa góc trong khoảng -180 đến 180 độ
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    
    return angle;
  }

  // Tính hướng (bearing) giữa hai điểm
  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * math.pi / 180;
    double startLng = start.longitude * math.pi / 180;
    double endLat = end.latitude * math.pi / 180;
    double endLng = end.longitude * math.pi / 180;
    
    double y = math.sin(endLng - startLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
            math.sin(startLat) * math.cos(endLat) * math.cos(endLng - startLng);
            
    double bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }

  IconData _getDirectionIcon(String instruction) {
    if (instruction.contains("Rẽ phải")) {
      return Icons.turn_right;
    } else if (instruction.contains("Rẽ trái")) {
      return Icons.turn_left;
    } else if (instruction.contains("Đi nhẹ sang phải")) {
      return Icons.turn_slight_right;
    } else if (instruction.contains("Đi nhẹ sang trái")) {
      return Icons.turn_slight_left;
    } else if (instruction.contains("Đã gần")) {
      return Icons.location_on;
    } else {
      return Icons.straight;
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}