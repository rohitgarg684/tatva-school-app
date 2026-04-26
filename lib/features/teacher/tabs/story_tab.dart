import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/story_post.dart';

class TeacherStoryTab extends StatelessWidget {
  final List<StoryPost> classStory;
  final List<ClassModel> classes;
  final String uid;
  final UserModel? user;
  final void Function(StoryPost) onStoryAdded;
  final void Function(int index, StoryPost updated) onStoryUpdated;

  const TeacherStoryTab({
    super.key,
    required this.classStory,
    required this.classes,
    required this.uid,
    required this.user,
    required this.onStoryAdded,
    required this.onStoryUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            FadeSlideIn(
                child: const Text('Class Story',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900,
                        letterSpacing: -0.8))),
            const SizedBox(height: 4),
            FadeSlideIn(
                delayMs: 60,
                child: Text(
                    classes.isNotEmpty
                        ? '${classes.first.name} · ${classStory.length} posts'
                        : 'No class story yet',
                    style: const TextStyle(
                        fontSize: 13, color: TatvaColors.neutral400))),
            const SizedBox(height: 16),
            if (classStory.isEmpty)
              Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.auto_stories_outlined,
                        color: TatvaColors.neutral400, size: 48),
                    const SizedBox(height: 12),
                    const Text('No stories yet',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral400)),
                    const SizedBox(height: 4),
                    const Text(
                        'Tap + to share the first class moment',
                        style: TextStyle(
                            fontSize: 12,
                            color: TatvaColors.neutral400)),
                  ]))),
            ...classStory.asMap().entries.map((e) {
              final post = e.value;
              final liked = post.isLikedBy(uid);
              final timeAgo = post.createdAt != null
                  ? _timeAgo(post.createdAt!)
                  : '';
              return StaggeredItem(
                  index: e.key,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade100)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    TatvaColors.primary.withOpacity(0.1),
                                child: Text(
                                    post.authorName.isNotEmpty
                                        ? post.authorName[0]
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.primary))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(post.authorName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: TatvaColors.neutral900)),
                                  if (post.authorRole.isNotEmpty)
                                    Text(post.authorRole,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                TatvaColors.neutral400)),
                                ])),
                            if (timeAgo.isNotEmpty)
                              Text(timeAgo,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: TatvaColors.neutral400)),
                          ]),
                          const SizedBox(height: 12),
                          Text(post.text,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: TatvaColors.neutral600,
                                  height: 1.5)),
                          const SizedBox(height: 12),
                          Row(children: [
                            GestureDetector(
                              onTap: () {
                                ApiService().toggleStoryLike(post.id);
                                final i = classStory
                                    .indexWhere((s) => s.id == post.id);
                                if (i == -1) return;
                                final p = classStory[i];
                                final updatedLikes =
                                    List<String>.from(p.likedBy);
                                p.isLikedBy(uid)
                                    ? updatedLikes.remove(uid)
                                    : updatedLikes.add(uid);
                                onStoryUpdated(
                                    i,
                                    StoryPost(
                                      id: p.id,
                                      authorUid: p.authorUid,
                                      authorName: p.authorName,
                                      authorRole: p.authorRole,
                                      classId: p.classId,
                                      className: p.className,
                                      text: p.text,
                                      mediaUrls: p.mediaUrls,
                                      mediaType: p.mediaType,
                                      likedBy: updatedLikes,
                                      commentCount: p.commentCount,
                                      createdAt: p.createdAt,
                                    ));
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        liked
                                            ? Icons.favorite_rounded
                                            : Icons
                                                .favorite_border_rounded,
                                        size: 18,
                                        color: liked
                                            ? TatvaColors.error
                                            : TatvaColors.neutral400),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: liked
                                                ? TatvaColors.error
                                                : TatvaColors.neutral400,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.comment_outlined,
                                size: 16,
                                color: TatvaColors.neutral400),
                            const SizedBox(width: 4),
                            Text('${post.commentCount}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ]),
                        ]),
                  ));
            }),
            const SizedBox(height: 80),
          ])),
      Positioned(
        right: 20,
        bottom: 20,
        child: GestureDetector(
          onTap: () => _showNewStorySheet(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: TatvaColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: TatvaColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ]),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ),
    ]);
  }

  void _showNewStorySheet(BuildContext context) {
    final textCtrl = TextEditingController();
    String storySelectedClassId = '';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('New Story Post',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                const SizedBox(height: 16),
                if (classes.length > 1)
                  StatefulBuilder(builder: (ctx2, setSheet) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.neutral400)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200)),
                            child: DropdownButton<String>(
                              value: storySelectedClassId.isNotEmpty &&
                                      classes.any((c) =>
                                          c.id == storySelectedClassId)
                                  ? storySelectedClassId
                                  : (classes.isNotEmpty
                                      ? classes.first.id
                                      : null),
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A2E22)),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF6B8F76)),
                              items: classes
                                  .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                          '${c.subject} — ${c.name}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Color(0xFF1A2E22)))))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setSheet(() =>
                                      storySelectedClassId = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ]);
                  }),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 14, color: TatvaColors.neutral900),
                  decoration: InputDecoration(
                    hintText: 'Share a class moment...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: TatvaColors.bgLight,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                TatvaColors.primary.withOpacity(0.5),
                            width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;
                    final selId = storySelectedClassId.isNotEmpty
                        ? storySelectedClassId
                        : (classes.isNotEmpty
                            ? classes.first.id
                            : '');
                    final selCls = classes
                        .cast<ClassModel?>()
                        .firstWhere((c) => c!.id == selId,
                            orElse: () => classes.isNotEmpty
                                ? classes.first
                                : null);
                    final classId = selCls?.id ?? '';
                    final className = selCls?.name ?? '';
                    final newPost = StoryPost(
                      authorUid: uid,
                      authorName: user?.name ?? '',
                      authorRole: 'Teacher',
                      classId: classId,
                      className: className,
                      text: text,
                      createdAt: DateTime.now(),
                    );
                    ApiService().createStoryPost(
                      classId: newPost.classId,
                      text: newPost.text,
                      className: newPost.className,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    onStoryAdded(newPost);
                    TatvaSnackbar.show(context, 'Story posted!');
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        color: TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  TatvaColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Center(
                        child: Text('Post',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
