import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/story_post.dart';
import '../parent_helpers.dart';

class ParentStoryTab extends StatelessWidget {
  final List<StoryPost> storyPosts;
  final String uid;
  final ValueChanged<String> onToggleLike;

  const ParentStoryTab({
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
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Updates from the classroom',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 24),
          if (storyPosts.isEmpty)
            FadeSlideIn(
                delayMs: 80,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.auto_stories_outlined,
                        color: TatvaColors.neutral400, size: 40),
                    const SizedBox(height: 12),
                    const Text('No story posts yet',
                        style: TextStyle(
                            fontSize: 14, color: TatvaColors.neutral400)),
                  ])),
                ))
          else
            ...storyPosts.asMap().entries.map((entry) {
              final i = entry.key;
              final post = entry.value;
              final timeAgo = post.createdAt != null
                  ? formatTimeAgo(post.createdAt!)
                  : '';
              return FadeSlideIn(
                  delayMs: 80 + i * 60,
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: i < storyPosts.length - 1 ? 14 : 0),
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
                                backgroundColor:
                                    TatvaColors.purple.withOpacity(0.1),
                                child: Text(
                                    post.authorName.isNotEmpty
                                        ? post.authorName[0]
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.purple))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(post.authorName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: TatvaColors.neutral900)),
                                  Text(
                                      '${post.authorRole}${post.className.isNotEmpty ? ' · ${post.className}' : ''}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: TatvaColors.neutral400)),
                                ])),
                            if (timeAgo.isNotEmpty)
                              Text(timeAgo,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: TatvaColors.neutral400)),
                          ]),
                          if (post.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(post.text,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: TatvaColors.neutral600,
                                    height: 1.5)),
                          ],
                          if (post.mediaUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                                height: 160,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Center(
                                    child: Icon(
                                        post.mediaType ==
                                                StoryMediaType.video
                                            ? Icons
                                                .play_circle_outline
                                            : Icons.image_outlined,
                                        color: TatvaColors.neutral400,
                                        size: 36))),
                          ],
                          const SizedBox(height: 10),
                          Row(children: [
                            GestureDetector(
                              onTap: () => onToggleLike(post.id),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        post.isLikedBy(uid)
                                            ? Icons.favorite_rounded
                                            : Icons
                                                .favorite_border_rounded,
                                        color: post.isLikedBy(uid)
                                            ? TatvaColors.error
                                            : TatvaColors.neutral400,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: post.isLikedBy(uid)
                                                ? TatvaColors.error
                                                : TatvaColors
                                                    .neutral400)),
                                  ]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: TatvaColors.neutral400, size: 15),
                            const SizedBox(width: 4),
                            Text('${post.commentCount}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ]),
                        ]),
                  ));
            }),
          const SizedBox(height: 24),
        ]));
  }
}
