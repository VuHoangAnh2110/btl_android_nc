import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';

class NewsService {
  static Future<List<Map<String, dynamic>>> fetchWeatherNews() async {
    final url = 'https://thoitietso.com/rss/ban-tin-thoi-tiet.rss';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.items.map((item) {
              // Trích xuất ảnh từ description
              String? imageUrl = _extractImageUrl(item.description ?? '');

              // Trích xuất nội dung sạch
              String cleanContent = _stripHtmlTags(item.description ?? '');
              
              // Phân tích ngày tháng từ chuỗi RFC822
              DateTime? pubDate;
              if (item.pubDate != null) {
                try {
                  // Sử dụng intl để phân tích định dạng RFC 822 (dùng cho RSS)
                  pubDate = _parseRFC822Date(item.pubDate!);
                } catch (e) {
                  print('Lỗi phân tích ngày: ${e.toString()}');
                  pubDate = null;
                }
              }

              return {
                'title': (item.title ?? 'Không có tiêu đề').trim(),
                'description': cleanContent,
                'link': item.link ?? '',
                'pubDate': pubDate,
                'imageUrl': imageUrl,
                'rawPubDate': item.pubDate, // Lưu chuỗi gốc để debug
              };
            }).toList();
      } else {
        throw Exception('Không thể tải RSS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải tin tức: $e');
    }
  }
  
  // Hàm phân tích định dạng ngày RFC 822
  static DateTime _parseRFC822Date(String dateString) {
    // Định dạng RFC 822: "Fri, 21 Feb 2025 08:17:52 +0700"
    
    // Sử dụng RegExp để xử lý chuỗi
    final pattern = RegExp(
      r'(\w+), (\d+) (\w+) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([+-]\d{4})'
    );
    
    final match = pattern.firstMatch(dateString);
    if (match != null) {
      // Lấy các thành phần của ngày
      final day = int.parse(match.group(2)!);
      final month = _parseMonth(match.group(3)!);
      final year = int.parse(match.group(4)!);
      final hour = int.parse(match.group(5)!);
      final minute = int.parse(match.group(6)!);
      final second = int.parse(match.group(7)!);
      
      // Chuyển đổi múi giờ
      String timezone = match.group(8)!;
      final tzHour = int.parse(timezone.substring(1, 3));
      final tzMinute = int.parse(timezone.substring(3, 5));
      final tzOffset = Duration(hours: tzHour, minutes: tzMinute);
      
      // Tạo DateTime với múi giờ UTC
      final dt = DateTime.utc(year, month, day, hour, minute, second);
      
      // Điều chỉnh theo múi giờ
      if (timezone.startsWith('+')) {
        return dt.subtract(tzOffset);
      } else {
        return dt.add(tzOffset);
      }
    }
    
    // Nếu không phù hợp với mẫu RegExp, thử với intl
    try {
      var formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US');
      return formatter.parse(dateString);
    } catch (e) {
      // Thử các định dạng khác nếu cần
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        throw FormatException('Không thể phân tích ngày: $dateString');
      }
    }
  }
  
  // Chuyển đổi tên tháng sang số
  static int _parseMonth(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    
    return months[month] ?? 1; // Mặc định tháng 1 nếu không tìm thấy
  }

  static String? _extractImageUrl(String htmlContent) {
    try {
      var document = parse(htmlContent);
      var imgElement = document.querySelector('img');
      return imgElement?.attributes['src'];
    } catch (e) {
      return null;
    }
  }

  static String _stripHtmlTags(String htmlContent) {
    final document = parse(htmlContent);
    final text = parse(document.body?.text ?? '').documentElement?.text ?? '';
    return text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
