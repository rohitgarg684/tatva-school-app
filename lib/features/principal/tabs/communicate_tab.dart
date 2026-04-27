import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/vote_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../messaging/messaging_screen.dart';

class CommunicateTab extends StatelessWidget {
  final List<VoteModel> voteModels;
  final List<UserModel> parents;
  final ApiService api;
  final VoidCallback onNewAnnouncement;
  final VoidCallback onCreateVote;
  final void Function(VoteModel vote) onVoteClosed;

  const CommunicateTab({
    super.key,
    required this.voteModels,
    required this.parents,
    required this.api,
    required this.onNewAnnouncement,
    required this.onCreateVote,
    required this.onVoteClosed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Communicate',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text(
                  'Announcements, votes and parent messages',
                  style: TextStyle(
                      fontSize: 13,
                      color: TatvaColors.neutral400))),
          SizedBox(height: 24),
          FadeSlideIn(
            delayMs: 80,
            child: Row(children: [
              Expanded(
                child: BouncyTap(
                  onTap: onNewAnnouncement,
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        TatvaColors.primary.withOpacity(0.9),
                        TatvaColors.primary
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: TatvaColors.primary
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: Icon(
                                  Icons.campaign_outlined,
                                  color: Colors.white,
                                  size: 20)),
                          SizedBox(height: 12),
                          Text('Announce',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(height: 2),
                          Text(
                              'Send to everyone\nor specific grades',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white
                                      .withOpacity(0.7),
                                  height: 1.4)),
                        ]),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: BouncyTap(
                  onTap: onCreateVote,
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        TatvaColors.purple.withOpacity(0.9),
                        TatvaColors.purple
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: TatvaColors.purple
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: Icon(
                                  Icons.how_to_vote_outlined,
                                  color: Colors.white,
                                  size: 20)),
                          SizedBox(height: 12),
                          Text('Create Vote',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(height: 2),
                          Text(
                              'Weather days, events\nor policy decisions',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white
                                      .withOpacity(0.7),
                                  height: 1.4)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),
          SizedBox(height: 28),
          FadeSlideIn(
            delayMs: 100,
            child: _buildVotesSection(context),
          ),
          SizedBox(height: 28),
          FadeSlideIn(
            delayMs: 120,
            child: Row(children: [
              Text('Message a Parent',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3)),
            ]),
          ),
          SizedBox(height: 12),
          ...List.generate(parents.length, (index) {
            final p = parents[index];
            final colors = [
              TatvaColors.success,
              TatvaColors.info,
              TatvaColors.accent,
              TatvaColors.purple,
              TatvaColors.error,
              TatvaColors.primary
            ];
            final pColor = colors[index % colors.length];
            final childName = p.children.isNotEmpty
                ? p.children.first.childName
                : '';
            final className = p.children.isNotEmpty
                ? p.children.first.className
                : '';
            return StaggeredItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                child: BouncyTap(
                  onTap: () => Navigator.push(
                    context,
                    TatvaPageRoute.slideRight(
                      MessagingScreen(
                        otherUserId: p.uid,
                        otherUserName: p.name,
                        otherUserRole: 'Parent of $childName',
                        otherUserEmail: p.email,
                        otherPhotoUrl: p.photoUrl,
                        avatarColor: pColor,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade100)),
                    child: Row(children: [
                      UserAvatar(
                        name: p.name,
                        radius: 22,
                        bgColor: pColor.withOpacity(0.12),
                        textColor: pColor,
                        photoUrl: p.photoUrl,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(p.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: TatvaColors
                                        .neutral900,
                                    letterSpacing: -0.2)),
                            Text(
                                'Parent of $childName',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors
                                        .neutral400)),
                            Text(className,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: TatvaColors
                                        .neutral400)),
                          ])),
                      Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5),
                              decoration: BoxDecoration(
                                  color: TatvaColors.purple
                                      .withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(
                                          20),
                                  border: Border.all(
                                      color: TatvaColors
                                          .purple
                                          .withOpacity(
                                              0.15))),
                              child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    Icon(
                                        Icons.chat_outlined,
                                        color: TatvaColors
                                            .purple,
                                        size: 13),
                                    SizedBox(width: 4),
                                    Text('Message',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: TatvaColors
                                                .purple,
                                            fontWeight:
                                                FontWeight
                                                    .w600)),
                                  ]),
                            ),
                            SizedBox(height: 4),
                            Text(p.email,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: TatvaColors
                                        .neutral400)),
                          ]),
                    ]),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Active Votes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.3)),
          SizedBox(width: 8),
          if (voteModels.isNotEmpty)
            PulseBadge(
                count: voteModels.length,
                color: TatvaColors.purple),
        ]),
        SizedBox(height: 12),
        if (voteModels.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.grey.shade100)),
            child: Column(children: [
              Icon(Icons.how_to_vote_outlined,
                  color: TatvaColors.neutral400, size: 28),
              SizedBox(height: 8),
              Text('No active votes',
                  style: TextStyle(
                      fontSize: 13,
                      color: TatvaColors.neutral400)),
              SizedBox(height: 4),
              Text('Tap "Create Vote" above to start one',
                  style: TextStyle(
                      fontSize: 11,
                      color: TatvaColors.neutral400)),
            ]),
          )
        else
          ...voteModels.map((vote) {
            final total = vote.totalVotes;
            final isOpen = vote.isVotingOpen;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: TatvaColors.purple
                          .withOpacity(0.2))),
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: TatvaColors.purple
                                  .withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(6)),
                          child: Text(vote.type.replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: TatvaColors.purple,
                                  fontWeight:
                                      FontWeight.w700))),
                      SizedBox(width: 8),
                      Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: isOpen
                                  ? TatvaColors.success.withOpacity(0.08)
                                  : TatvaColors.neutral400.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(6)),
                          child: Text(isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isOpen ? TatvaColors.success : TatvaColors.neutral400,
                                  fontWeight: FontWeight.w700))),
                      Spacer(),
                      Icon(Icons.people_outline,
                          color: TatvaColors.neutral400,
                          size: 13),
                      SizedBox(width: 4),
                      Text('$total voted',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  TatvaColors.neutral400)),
                      if (isOpen) ...[
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            await api.closeVote(vote.id);
                            onVoteClosed(vote);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Vote closed',
                                          style: TextStyle()),
                                      backgroundColor:
                                          TatvaColors.neutral600,
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))));
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3),
                              decoration: BoxDecoration(
                                  color: TatvaColors.error
                                      .withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(6)),
                              child: Text('Close',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: TatvaColors.error,
                                      fontWeight: FontWeight.w700))),
                        ),
                      ],
                    ]),
                    SizedBox(height: 10),
                    Text(vote.question,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900,
                            height: 1.3)),
                    if (total > 0) ...[
                      SizedBox(height: 12),
                      ...vote.options.map((opt) {
                        final count = vote.votes[opt] ?? 0;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: _voteResultBar(
                              opt.replaceAll('_', ' '), count, total, _optionColor(opt)),
                        );
                      }),
                    ],
                  ]),
            );
          }),
      ],
    );
  }

  Color _optionColor(String opt) {
    switch (opt) {
      case 'school': return TatvaColors.success;
      case 'no_school': return TatvaColors.error;
      case 'undecided': return TatvaColors.accent;
      default: return TatvaColors.info;
    }
  }

  Widget _voteResultBar(
      String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0;
    return Row(children: [
      SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, color: TatvaColors.neutral400))),
      Expanded(
          child: AnimatedProgressBar(
              value: pct, color: color, height: 5, delayMs: 0)),
      SizedBox(width: 8),
      Text('$count',
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    ]);
  }
}
