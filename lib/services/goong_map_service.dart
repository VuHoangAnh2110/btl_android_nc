import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GoongMapService {
  static const String API_KEY = "UOkJv1Wnm9uD2cokFDzqxXRmM0AvWdClHbKRE3jK";
  static const String MAP_TILES_KEY = "kmc5e4biI5WVwxOws2Mt6HieJL6FIwK1bb3rxk3G";
  
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    final url = Uri.parse(
      'https://rsapi.goong.io/Place/AutoComplete?api_key=$API_KEY&input=$query'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
    }
    
    return [];
  }
  
  static Future<Map<String, dynamic>?> getPlaceDetail(String placeId) async {
    final url = Uri.parse(
      'https://rsapi.goong.io/Place/Detail?api_key=$API_KEY&place_id=$placeId'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      }
    }
    
    return null;
  }
  
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://rsapi.goong.io/Geocode?api_key=$API_KEY&latlng=$lat,$lng'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    }
    
    return "Unknown location";
  }

  // Cập nhật phương thức getDirections

  static Future<Map<String, dynamic>?> getDirections(
    double fromLat, 
    double fromLng, 
    double toLat, 
    double toLng,
  ) async {
    try {
      final url = Uri.parse(
        'https://rsapi.goong.io/Direction?origin=$fromLat,$fromLng&destination=$toLat,$toLng&vehicle=car&api_key=UOkJv1Wnm9uD2cokFDzqxXRmM0AvWdClHbKRE3jK'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print("API Response: ${response.body}"); // Debug log
        
        if (data['status'] == 'OK' || data['routes'] != null) {
          try {
            // Lấy thông tin tuyến đường từ định dạng JSON mà Goong API trả về
            final routes = data['routes'];
            if (routes != null && routes.isNotEmpty) {
              final route = routes[0];
              final legs = route['legs'];
              
              if (legs != null && legs.isNotEmpty) {
                final leg = legs[0];
                final distance = leg['distance']['text'];
                final duration = leg['duration']['text'];
                
                // Giải mã polyline từ cấu trúc thực tế
                List<LatLng> points = [];
                if (route.containsKey('overview_polyline') && 
                    route['overview_polyline'].containsKey('points')) {
                  points = _decodePolyline(route['overview_polyline']['points']);
                } else {
                  // Nếu không có overview_polyline, lấy từ các steps
                  for (var step in leg['steps']) {
                    if (step.containsKey('polyline') && step['polyline'].containsKey('points')) {
                      List<LatLng> stepPoints = _decodePolyline(step['polyline']['points']);
                      points.addAll(stepPoints);
                    }
                  }
                }
                
                // Nếu không có points nào, ít nhất tạo một đường thẳng từ điểm xuất phát đến đích
                if (points.isEmpty) {
                  points = [
                    LatLng(fromLat, fromLng),
                    LatLng(toLat, toLng)
                  ];
                }
                
                return {
                  'points': points,
                  'distance': distance,
                  'duration': duration,
                };
              }
            }
          } catch (e) {
            print('Lỗi xử lý dữ liệu chỉ đường: $e');
          }
        } else {
          print("API trạng thái không phải OK: ${data['status']}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Exception khi gọi API chỉ đường: $e");
    }
    
    // Trả về đường thẳng đơn giản nếu API fails
    return {
      'points': [LatLng(fromLat, fromLng), LatLng(toLat, toLng)],
      'distance': 'Không xác định',
      'duration': 'Không xác định',
    };
  }
  
  // Phương thức _decodePolyline cập nhật

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    
    // Kiểm tra nếu chuỗi rỗng
    if (encoded.isEmpty) {
      return poly;
    }
    
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < len);
        
        if (index >= len && b >= 0x20) {
          break; // Tránh lỗi nếu chuỗi mã bị hỏng
        }
        
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        
        shift = 0;
        result = 0;
        
        if (index < len) {
          do {
            b = encoded.codeUnitAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
          } while (b >= 0x20 && index < len);
          
          if (index >= len && b >= 0x20) {
            break; // Tránh lỗi nếu chuỗi mã bị hỏng
          }
          
          int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
          lng += dlng;
        }
        
        double latDouble = lat / 1E5;
        double lngDouble = lng / 1E5;
        
        // Kiểm tra giá trị hợp lệ trước khi thêm vào
        if (latDouble >= -90 && latDouble <= 90 && 
            lngDouble >= -180 && lngDouble <= 180) {
          poly.add(LatLng(latDouble, lngDouble));
        }
      }
    } catch (e) {
      print("Lỗi khi giải mã polyline: $e");
    }
    
    // Nếu không giải mã được hoặc kết quả rỗng, trả về danh sách rỗng
    return poly;
  }
  
  // URL cho map tiles
  static String get mapTilesUrl {
    return 'https://tiles.goong.io/tiles/v2/roadmap/{z}/{x}/{y}.png?api_key=$API_KEY';
  }
  
  // URL dự phòng
  static String get mapTilesUrlAlt {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }
}