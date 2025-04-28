class EvacuationArea {
  final String id;
  final String name;
  final String address;
  final String description;
  final double latitude;
  final double longitude;
  final int capacity;
  final String status; // "active", "inactive"
  final DateTime createdAt;

  EvacuationArea({
    this.id = '',
    required this.name,
    required this.address,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    this.status = 'active',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EvacuationArea.fromMap(Map<String, dynamic> map, String id) {
    return EvacuationArea(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      capacity: map['capacity']?.toInt() ?? 0,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}