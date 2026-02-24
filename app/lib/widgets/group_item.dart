import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/group.dart';
import '../../screens/group/group_detail_screen.dart';
import '../../screens/group/group_edit_screen.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import 'common/bounceable.dart';
import 'like_button.dart';
import 'common/custom_dialog.dart';

class GroupItem extends StatelessWidget {
  final Group group;
  final bool isAdmin;
  final VoidCallback? onDelete; // 삭제 후 콜백 (필요 시)

  const GroupItem({
    super.key,
    required this.group,
    required this.isAdmin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isExpired = group.isExpired;

    return Slidable(
      key: Key(group.id),
      enabled: isAdmin || group.isMyGroup, // 내 글이거나 관리자면 가능
      startActionPane: group.isMyGroup
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                CustomSlidableAction(
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupEditScreen(group: group),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF3182F6), // 파란색
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E8EB)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, size: 28),
                        SizedBox(height: 4),
                        Text(
                          "수정",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              _confirmDelete(context, group);
            },
            backgroundColor: const Color(0xFFE93D3D).withOpacity(0.8),
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E8EB)),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin ? "삭제 (관리자)" : "삭제",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Bounceable(
        onTap: (isExpired && !group.isMyGroup && !isAdmin)
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(group: group),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: isExpired ? 0.7 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpired ? Colors.grey[200] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpired
                    ? Colors.transparent
                    : const Color(0xFFE5E8EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 제목 & 찜 버튼
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        group.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: LikeButton(
                        isLiked: group.isLiked,
                        likeCount: group.likeCount,
                        enabled: !isExpired, // 마감된 경우 비활성화
                        onTap: () {
                          FirestoreService().toggleGroupLike(
                            group.id,
                            group.isLiked,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. 해시태그
                Wrap(
                  spacing: 6,
                  children: group.hashtags
                      .map(
                        (tag) => Text(
                          tag,
                          style: TextStyle(
                            color: isExpired
                                ? Colors.grey
                                : const Color(0xFF3182F6),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),

                // 3. 정보 (인원, 마감일)
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      group.maxMembers == -1
                          ? "제한 없음"
                          : "${group.maxMembers}명 모집",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    // 댓글 수 표시
                    if (group.qnaList.isNotEmpty) ...[
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${group.qnaList.length}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(width: 1, height: 10, color: Colors.grey[300]),
                    const SizedBox(width: 12),
                    Text(
                      isExpired
                          ? "마감됨"
                          : "D-${group.deadline.difference(DateTime.now()).inDays}",
                      style: TextStyle(
                        color: isExpired
                            ? Colors.grey
                            : const Color(0xFFFF4E4E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "관리자 권한으로 삭제",
        contentText: "정말로 이 모집글을 삭제하시겠습니까?",
        cancelText: "취소",
        confirmText: "삭제",
        isDestructive: true,
        onConfirm: () async {
          await FirestoreService().deleteGroup(group.id);
          if (context.mounted) {
            Navigator.pop(ctx);
            ToastUtils.show(context, "모집이 삭제되었습니다.");
            onDelete?.call();
          }
        },
      ),
    );
  }
}
