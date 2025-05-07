class Nguoi {
  final String id;
  final String ten;
  final String gioiTinh;
  final double diem;

  Nguoi({
    required this.id,
    required this.ten,
    required this.gioiTinh,
    required this.diem,
  });

  factory Nguoi.fromMap(String id, Map<String, dynamic> map) {
    return Nguoi(
      id: id,
      ten: map['ten'] ?? '',
      gioiTinh: map['gioiTinh'] ?? '',
      diem: (map['diem'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ten': ten,
      'gioiTinh': gioiTinh,
      'diem': diem,
    };
  }
}