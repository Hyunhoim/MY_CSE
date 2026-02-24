import 'package:flutter/material.dart';
import 'dart:async'; // StreamSubscription 사용을 위해 추가
import 'package:animate_do/animate_do.dart'; // NEW
import 'package:flutter_slidable/flutter_slidable.dart'; // ★ 재추가
import '../../models/group.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/common/custom_loading_indicator.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/like_button.dart';
import '../../widgets/common/bounceable.dart'; // Toss-style Interaction // ★ 추가
import 'group_detail_screen.dart';
import 'group_create_screen.dart';
import 'group_edit_screen.dart';
import '../../widgets/group_item.dart'; // NEW // ★ 추가

class GroupListScreen extends StatefulWidget {
  final String filterType; // 'all', 'my', 'liked'

  const GroupListScreen({super.key, this.filterType = 'all'});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAdmin = false;
  late Stream<List<Group>> _groupStream;

  // ★ AnimatedList용 변수 (liked 필터일 때만 사용)
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Group> _displayedLikedGroups = [];
  StreamSubscription<List<Group>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();

    if (widget.filterType == 'liked') {
      // 찜 목록은 애니메이션 처리를 위해 수동 구독
      _subscription = _firestoreService.getGroups('liked').listen((groups) {
        _processLikedUpdates(groups);
      });
    } else {
      // 나머지는 기존 스트림 빌더 사용
      _groupStream = _firestoreService.getGroups(widget.filterType);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminRole() async {
    String role = await _firestoreService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'ADMIN');
      });
    }
  }

  // ★ 찜 목록 데이터 갱신 및 애니메이션 처리
  void _processLikedUpdates(List<Group> newGroups) {
    if (!mounted) return;

    // 초기 로딩
    if (_displayedLikedGroups.isEmpty && newGroups.isNotEmpty) {
      setState(() {
        _displayedLikedGroups = List.from(newGroups);
      });
      return;
    }

    // 1. 삭제된 항목 처리 (찜 해제) - 역순으로 처리하여 인덱스 꼬임 방지
    for (int i = _displayedLikedGroups.length - 1; i >= 0; i--) {
      final oldItem = _displayedLikedGroups[i];
      final exists = newGroups.any((g) => g.id == oldItem.id);

      if (!exists) {
        // 실제 데이터에서 제거
        final removedItem = _displayedLikedGroups.removeAt(i);
        // 애니메이션과 함께 제거
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildAnimatedGroupItem(removedItem, animation),
          duration: const Duration(milliseconds: 500),
        );
      }
    }

    // 2. 추가/업데이트된 항목 처리
    // 리스트 전체가 완전히 바뀌는 것보다, 기존 위치 유지하면서 업데이트하는 것이 중요
    // 여기서는 간단히 새로 추가된 것만 감지하거나, 데이터 갱신
    for (int i = 0; i < newGroups.length; i++) {
      final newItem = newGroups[i];
      final index = _displayedLikedGroups.indexWhere((g) => g.id == newItem.id);

      if (index != -1) {
        // 이미 있으면 업데이트 (좋아요 수 변경 등 반영)
        _displayedLikedGroups[index] = newItem;
      } else {
        // 새로 추가됨 (다른 탭에서 찜 했을 때)
        // 맨 앞에 추가하거나 적절한 위치에 추가
        _displayedLikedGroups.insert(i, newItem);
        _listKey.currentState?.insertItem(i);
      }
    }

    // 비어있게 된 경우 화면 갱신을 위해 setState 호출 필요할 수 있음
    if (_displayedLikedGroups.isEmpty && newGroups.isEmpty) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★ 찜 목록일 경우 AnimatedList 반환
    if (widget.filterType == 'liked') {
      if (_displayedLikedGroups.isEmpty && _subscription == null) {
        // 아직 로딩 전이거나 데이터 없음 (초기 상태)
        // Subscription이 있으면 데이터가 없는 것이므로 빈 화면 표시
        return _buildEmptyView();
      }

      if (_displayedLikedGroups.isEmpty) {
        return _buildEmptyView();
      }

      return ListView(
        // AnimatedList를 감싸서 패딩 등 처리
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // 외부 ListView 스크롤 사용
            initialItemCount: _displayedLikedGroups.length,
            itemBuilder: (context, index, animation) {
              if (index >= _displayedLikedGroups.length) {
                return const SizedBox();
              }
              return _buildAnimatedGroupItem(
                _displayedLikedGroups[index],
                animation,
              );
            },
          ),
        ],
      );
    }

    // 기존 로직 (전체, 내 모집)
    return StreamBuilder<List<Group>>(
      stream: _groupStream,
      builder: (context, snapshot) {
        // 1. 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        // 2. 에러 발생
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "잠시 오류가 발생했어요.\n${snapshot.error}",
              textAlign: TextAlign.center,
            ),
          );
        }

        // 3. 데이터 없음 또는 빈 리스트
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildEmptyView();
        }

        // 4. 리스트 출력
        final allGroups = groups;

        // 필터링: 공식글과 일반글 분리 (전체 목록일 때만 분리)
        List<Group> officialGroups = [];
        List<Group> generalGroups = [];

        if (widget.filterType == 'all') {
          officialGroups = allGroups.where((g) => g.isOfficial).toList();
          generalGroups = allGroups.where((g) => !g.isOfficial).toList();
        } else {
          generalGroups = allGroups;
        }

        // 정렬 로직: 마감된 것은 맨 뒤로
        if (widget.filterType == 'all') {
          officialGroups = [
            ...officialGroups.where((g) => !g.isExpired),
            ...officialGroups.where((g) => g.isExpired),
          ];
        }

        generalGroups = [
          // 1. 진행 중 + 찜함
          ...generalGroups.where((g) => !g.isExpired && g.isLiked),
          // 2. 진행 중 + 찜 안함
          ...generalGroups.where((g) => !g.isExpired && !g.isLiked),
          // 3. 마감됨 + 찜함
          ...generalGroups.where((g) => g.isExpired && g.isLiked),
          // 4. 마감됨 + 찜 안함
          ...generalGroups.where((g) => g.isExpired && !g.isLiked),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            // 1. 공식(학생회) 섹션 (가로 스크롤) - 전체 목록일 때만
            if (widget.filterType == 'all' && officialGroups.isNotEmpty) ...[
              SizedBox(
                height: 170, // 카드 높이 지정
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: officialGroups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildOfficialCard(officialGroups[index]);
                  },
                ),
              ),
              const SizedBox(height: 24), // 섹션 간 간격
            ],

            // 2. 일반 공고 리스트
            if (generalGroups.isEmpty && officialGroups.isEmpty)
              _buildEmptyView() // 데이터는 있는데 필터링 후 없을 경우
            else if (generalGroups.isNotEmpty)
              ...generalGroups.asMap().entries.map((entry) {
                int index = entry.key;
                Group group = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: index * 50),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GroupItem(
                      group: group,
                      isAdmin: _isAdmin,
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyView() {
    String emptyMsg = "지금은 모집 중인 글이 없어요.";
    if (widget.filterType == 'my') emptyMsg = "내가 만든 모집이 없어요.";
    if (widget.filterType == 'liked') emptyMsg = "찜한 모집이 없어요.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            emptyMsg,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ★ 애니메이션 아이템 빌더
  Widget _buildAnimatedGroupItem(Group group, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GroupItem(
            group: group,
            isAdmin: _isAdmin,
          ),
        ),
      ),
    );
  }

  // ... (나머지 _buildOfficialCard 메서드는 그대로 유지)

  // ★ 공식 공고 카드 위젯
  Widget _buildOfficialCard(Group group) {
    bool isExpired = group.isExpired;

    return Bounceable(
      onTap: (isExpired && !group.isMyGroup && !_isAdmin)
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
        opacity: isExpired ? 0.6 : 1.0, // 전체 투명도 적용
        child: Container(
          width: 280, // 가로 고정 너비
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isExpired
                ? Colors.grey[200] // 마감 시 회색 배경
                : const Color(0xFFE8F3FF), // 활성 시 파란 배경
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpired
                  ? Colors.grey[300]!
                  : const Color(0xFF3182F6).withOpacity(0.3), // ★ 다시 파란색 보더로 복구
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors
                                .grey // 마감 시 회색 뱃지
                          : const Color(0xFF3182F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "학생회",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    group.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? Colors.grey[600] // 마감 시 회색 텍스트
                          : const Color(0xFF191F28),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isExpired
                        ? Colors
                              .grey // 마감 시 회색 아이콘
                        : const Color(0xFF3182F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpired
                        ? "마감됨"
                        : "D-${group.deadline.difference(DateTime.now()).inDays}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? Colors
                                .grey // 마감 시 회색 텍스트
                          : const Color(0xFF3182F6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
