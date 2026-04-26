import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../models/story_post.dart';

class StudentStoryTab extends StatelessWidget {
  final List<StoryPost> storyPosts;
  final String uid;
  final void Function(StoryPost post) onToggleLike;

  const StudentStoryTab({
    super.key,
    required this.storyPosts,
    required this.uid,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: Text('${storyPosts.length} posts from your class',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        if (storyPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48, color: TatvaColors.neutral400.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No stories yet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
              ]),
            ),
          )
        else
          ...List.generate(storyPosts.length, (i) {
            final post = storyPosts[i];
            final timeAgo = post.createdAt != null ? _formatTimeAgo(post.createdAt!) : '';
            return StaggeredItem(
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor: TatvaColors.info.withOpacity(0.1),
                            child: Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0]
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.info))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(post.authorName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: TatvaColors.neutral900)),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: TatvaColors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(post.authorRole,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: TatvaColors.purple)),
                                ),
                                const SizedBox(width: 6),
                                Text(timeAgo,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: TatvaColors.neutral400)),
                              ]),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      Text(post.text,
                          style: const TextStyle(
                              fontSize: 13,
                              color: TatvaColors.neutral600,
                              height: 1.5)),
                      if (post.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                const Icon(Icons.photo_library_outlined,
                                    color: TatvaColors.neutral400, size: 18),
                                const SizedBox(width: 6),
                                Text('${post.mediaUrls.length} photo${post.mediaUrls.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: TatvaColors.neutral400)),
                              ])),
                        ),
                      ],
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => onToggleLike(post),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              post.isLikedBy(uid)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: post.isLikedBy(uid) ? TatvaColors.error : TatvaColors.neutral400),
                          const SizedBox(width: 4),
                          Text('${post.likeCount}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.neutral600)),
                        ]),
                      ),
                    ]),
              ),
            );
          }),
        const SizedBox(height: 24),
      ]),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
