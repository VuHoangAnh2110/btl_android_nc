import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evacuation_area.dart';
import '../../services/evacuation_service.dart';
import '../../services/goong_map_service.dart';
import 'dart:math' as math;

class AddEvacuationArea extends StatefulWidget {
  @override
  _AddEvacuationAreaState createState() => _AddEvacuationAreaState();
}

class _AddEvacuationAreaState extends State<AddEvacuationArea> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _searchController = TextEditingController();
  
  final EvacuationService _evacuationService = EvacuationService();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  
  // Vị trí mặc định (Hà Nội)
  LatLng _selectedLocation = LatLng(21.0278, 105.8342);
  final MapController _mapController = MapController();
  
  Marker? _marker;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _marker = Marker(
      point: _selectedLocation,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    );
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _marker = Marker(
          point: _selectedLocation,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        );
      });
      
      _mapController.move(_selectedLocation, 15);
      _updateAddress();
    } catch (e) {
      print("Error getting location: $e");
    }
  }
  
  void _updateAddress() async {
    try {
      String address = await GoongMapService.getAddressFromLatLng(
        _selectedLocation.latitude, 
        _selectedLocation.longitude
      );
      setState(() {
        _addressController.text = address;
      });
    } catch (e) {
      print("Error getting address: $e");
    }
  }
  
  void _searchPlaces(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await GoongMapService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print("Error searching places: $e");
    }
  }
  
  void _selectPlace(String placeId, String description) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _searchController.clear();
    });
    
    try {
      final placeDetails = await GoongMapService.getPlaceDetail(placeId);
      if (placeDetails != null && placeDetails['geometry'] != null) {
        final location = placeDetails['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        
        setState(() {
          _selectedLocation = LatLng(lat, lng);
          _marker = Marker(
            point: _selectedLocation,
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          );
          _addressController.text = description;
        });
        
        _mapController.move(_selectedLocation, 15);
      }
    } catch (e) {
      print("Error getting place details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _marker = Marker(
        point: point,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      );
    });
    
    _updateAddress();
  }
  
  void _saveEvacuationArea() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        final newArea = EvacuationArea(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          capacity: int.parse(_capacityController.text.trim()),
        );
        
        await _evacuationService.addEvacuationArea(newArea);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm khu vực di tản thành công'))
        );
        
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}'))
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm khu vực di tản'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map section
                    Text(
                      'Chọn vị trí trên bản đồ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 15,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=SZiHm8nz31ezgVgMdqrO',
                              // Hoặc dùng URL dự phòng nếu gặp lỗi:
                              // urlTemplate: GoongMapService.mapTilesUrlAlt,
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: _marker != null ? [_marker!] : [],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Search section
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Tìm kiếm địa điểm',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      ),
                      onChanged: _searchPlaces,
                    ),
                    
                    // Search results
                    if (_isSearching)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        height: math.min(_searchResults.length * 60.0, 180.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(result['description'] ?? '', 
                                         style: TextStyle(fontSize: 14)),
                              onTap: () => _selectPlace(
                                result['place_id'], 
                                result['description']
                              ),
                            );
                          },
                        ),
                      ),
                      
                    SizedBox(height: 16),
                    
                    // Form fields
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên khu vực di tản',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên khu vực';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _capacityController,
                      decoration: InputDecoration(
                        labelText: 'Sức chứa (số người)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập sức chứa';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Sức chứa phải là số dương';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveEvacuationArea,
                        child: Text('Lưu khu vực di tản'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
}