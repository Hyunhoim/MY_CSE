import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import 'common/bounceable.dart';
import 'common/jelly_button.dart';
import 'common/custom_dialog.dart';

class NoticeItem extends StatelessWidget {
  final Notice notice;
  final bool isRead;
  final bool isScraped;
  final String userRole;
  final VoidCallback? onScrapToggle;

  const NoticeItem({
    super.key,
    required this.notice,
    required this.isRead,
    required this.isScraped,
    required this.userRole,
    this.onScrapToggle,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case "긴급":
        return Colors.red[700]!;
      case "학사":
        return Colors.blue[700]!;
      case "장학":
        return Colors.orange[700]!;
      case "취업":
        return Colors.green[700]!;
      case "학과행사":
        return Colors.purple[700]!;
      case "외부행사":
        return Colors.grey[700]!;
      case "공모전":
        return Colors.amber[700]!;
      default:
        return const Color(0xFF3182F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Bounceable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFE8F3FF), // 읽지 않았으면 연한 파란 배경
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? const Color(0xFFE5E8EB)
                : const Color(0xFF3182F6), // 읽지 않았으면 파란 테두리
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  notice.date,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRead
                        ? const Color(0xFF8B95A1)
                        : const Color(0xFF3182F6), // 읽지 않았으면 날짜도 파란색
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const Spacer(),
                JellyButton(
                  isActive: isScraped,
                  activeIcon: Icons.bookmark_rounded,
                  inactiveIcon: Icons.bookmark_border_rounded,
                  activeColor: const Color(0xFFFFD180),
                  inactiveColor: const Color(0xFFD1D6DB),
                  onTap: () {
                    // 상위에서 처리하거나 직접 서비스 호출
                    if (onScrapToggle != null) {
                      onScrapToggle!();
                    } else {
                      FirestoreService().toggleNoticeScrap(
                        notice.id,
                        isScraped,
                      );
                      ToastUtils.show(
                        context,
                        !isScraped ? "스크랩 보관함에 저장되었어요." : "스크랩이 해제되었어요.",
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 제목 Row
            Text(
              notice.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isRead
                    ? FontWeight.normal
                    : FontWeight.bold, // 읽지 않았으면 볼드
                color: const Color(0xFF191F28),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(notice.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    notice.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getCategoryColor(notice.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (notice.isUrgent == true) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE), // Pastel Red
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "긴급",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD32F2F), // Strong Red
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  notice.author.isNotEmpty ? notice.author : "학과사무실",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 14,
                  color: Color(0xFFB0B8C1),
                ),
                const SizedBox(width: 4),
                Text(
                  "${notice.views}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // 관리자가 아니면 그냥 카드 반환
    if (userRole != 'ADMIN') {
      return card;
    }

    // 관리자면 슬라이드 기능 추가
    return Slidable(
      key: Key(notice.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              // 삭제 확인 다이얼로그
              bool confirm =
                  await showDialog(
                    context: context,
                    builder: (context) => CustomDialog(
                      title: "공지 삭제",
                      contentText: "정말로 이 공지를 삭제하시겠습니까?",
                      cancelText: "취소",
                      confirmText: "삭제",
                      isDestructive: true,
                      onConfirm: () => Navigator.pop(context, true),
                      onCancel: () => Navigator.pop(context, false),
                    ),
                  ) ??
                  false;

              if (confirm) {
                await FirestoreService().deleteNotice(notice.id);
                if (context.mounted) {
                  ToastUtils.show(context, "공지가 삭제되었습니다.");
                }
              }
            },
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: card,
    );
  }
}
