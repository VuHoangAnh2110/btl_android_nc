import 'package:cloud_firestore/cloud_firestore.dart';

class NhanVien {
  final String id;
  final String maNhanVien;
  final String hoTen;
  final DateTime ngaySinh;
  final String gioiTinh;
  final String chucVu;
  final double heSoLuong;
  final double luongCoBan;

  NhanVien({
    required this.id,
    required this.maNhanVien,
    required this.hoTen,
    required this.ngaySinh,
    required this.gioiTinh,
    required this.chucVu,
    required this.heSoLuong,
    required this.luongCoBan,
  });


  factory NhanVien.fromMap(String id, Map<String, dynamic> map) {
    return NhanVien(
      id: id,
      maNhanVien: map['maNhanVien'] ?? '',
      hoTen: map['hoTen'] ?? '',
      ngaySinh: map['ngaySinh'] != null 
          ? (map['ngaySinh'] as Timestamp).toDate() 
          : DateTime.now(),
      gioiTinh: map['gioiTinh'] ?? '',
      chucVu: map['chucVu'] ?? '',
      heSoLuong: (map['heSoLuong'] ?? 0).toDouble(),
      luongCoBan: (map['luongCoBan'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maNhanVien': maNhanVien,
      'hoTen': hoTen,
      'ngaySinh': Timestamp.fromDate(ngaySinh),
      'gioiTinh': gioiTinh,
      'chucVu': chucVu,
      'heSoLuong': heSoLuong,
      'luongCoBan': luongCoBan,
    };
  }
}