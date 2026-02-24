import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String category;
  final String title;
  final String link;
  final String date;
  final String content;
  final List<String> imageUrls;
  final String author;
  final int views;
  final int viewsToday;
  final List<Map<String, String>> files;
  bool isScraped;
  final bool? isImportant;
  final bool? isUrgent;
  final bool isDeleted;
  final bool isRead;
  final DocumentSnapshot? doc;
  final DateTime? parsedDate; // NEW: 성능 최적화용 파싱된 날짜

  Notice({
    required this.id,
    required this.category,
    required this.title,
    this.link = '',
    required this.date,
    required this.content,
    this.imageUrls = const [],
    this.author = "학과사무실",
    this.views = 0,
    this.viewsToday = 0,
    this.files = const [],
    this.isScraped = false,
    this.isImportant = false,
    this.isUrgent = false,
    this.isDeleted = false,
    this.isRead = true,
    this.doc,
    this.parsedDate, // NEW
  });

  factory Notice.fromFirestore(
    DocumentSnapshot doc,
    List<String> userScraps, [
    List<String> userReadNotices = const [],
  ]) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // ★ 날짜 변환 로직 개선
    String formattedDate = '';
    DateTime? parsed;

    try {
      if (data['date'] is Timestamp) {
        // 1. 타임스탬프인 경우 (default)
        parsed = (data['date'] as Timestamp).toDate();
        formattedDate =
            "${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')}";
      } else if (data['date'] is String) {
        // 2. 문자열인 경우
        String dateStr = data['date'].toString().trim();
        formattedDate = dateStr;

        // 파싱 시도 (다양한 포맷 지원)
        // 구분자 통일
        String cleanDate = dateStr.replaceAll('/', '.').replaceAll('-', '.');
        List<String> parts = cleanDate.split('.');
        if (parts.length >= 3) {
          int? year = int.tryParse(parts[0]);
          int? month = int.tryParse(parts[1]);
          int? day = int.tryParse(parts[2]);
          if (year != null && month != null && day != null) {
            parsed = DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      formattedDate = '날짜 없음';
    }

    // 첨부파일 파싱
    List<Map<String, String>> parsedFiles = [];
    try {
      if (data['files'] != null && data['files'] is List) {
        for (var f in data['files']) {
          if (f is Map) {
            parsedFiles.add({
              'name': f['name']?.toString() ?? '첨부파일',
              'url': f['url']?.toString() ?? '',
            });
          }
        }
      }
    } catch (e) {
      // 파일 파싱 실패 시 무시
    }

    return Notice(
      id: doc.id,
      category: data['category']?.toString() ?? '공지',
      title: data['title']?.toString() ?? '',
      link: data['link']?.toString() ?? '',
      date: formattedDate,
      content: data['content']?.toString() ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? data['images'] ?? []),
      author: data['author']?.toString() ?? '학과사무실',
      views: (data['views'] is int) ? data['views'] : 0,
      viewsToday: (data['views_today'] is int) ? data['views_today'] : 0,
      files: parsedFiles,
      isScraped: userScraps.contains(doc.id),
      isRead: userReadNotices.contains(doc.id),
      isImportant: data['is_important'] ?? false,
      isUrgent: data['is_urgent'] ?? false,
      isDeleted: data['is_deleted'] ?? false,
      doc: doc,
      parsedDate: parsed, // NEW
    );
  }
}
