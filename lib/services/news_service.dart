import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:html/parser.dart';

class NewsService {
  static Future<List<Map<String, dynamic>>> fetchWeatherNews() async {
    final url = 'https://thoitietso.com/rss/ban-tin-thoi-tiet.rss';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.items?.map((item) {
              // Trích xuất ảnh từ description
              String? imageUrl = _extractImageUrl(item.description ?? '');

              // Trích xuất nội dung sạch
              String cleanContent = _stripHtmlTags(item.description ?? '');

              return {
                'title': (item.title ?? 'Không có tiêu đề').trim(),
                'description': cleanContent,
                'link': item.link ?? '',
                'pubDate': item.pubDate,
                'imageUrl': imageUrl,
              };
            }).toList() ??
            [];
      } else {
        throw Exception('Không thể tải RSS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải tin tức: $e');
    }
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
