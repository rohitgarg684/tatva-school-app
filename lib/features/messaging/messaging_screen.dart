import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/message_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/message_service.dart';
import '../../shared/animations/animations.dart';

class MessagingScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String otherUserEmail;
  final Color avatarColor;

  const MessagingScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.otherUserEmail,
    this.avatarColor = const Color(0xFF2E6B4F),
  });

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  static const Color bg = Color(0xFFF4F9F4);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2E6B4F);
  static const Color textDark = Color(0xFF1A2E22);
  static const Color textLight = Color(0xFF8FAF8F);

  final _msgSvc = MessageService();
  List<MessageModel> _messages = [];
  StreamSubscription? _msgSubscription;
  late String _myUid;
  late String _conversationId;

  @override
  void initState() {
    super.initState();
    _myUid = AuthRepository().currentUid ?? 'parent_suresh';
    _conversationId = _msgSvc.makeConversationId(_myUid, widget.otherUserId);
    _msgSubscription =
        _msgSvc.getMessages(_conversationId).listen((msgs) {
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _msgSubscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgController.clear();
    HapticFeedback.lightImpact();

    await _msgSvc.send(MessageModel(
      text: text,
      senderUid: _myUid,
      receiverUid: widget.otherUserId,
      conversationId: _conversationId,
    ));

    if (mounted) setState(() => _sending = false);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bgCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: widget.avatarColor.withOpacity(0.12),
            child: Text(
              widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.avatarColor),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName,
                style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            Text(widget.otherUserRole,
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 11, color: textLight)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.email_outlined, color: primary, size: 20),
            onPressed: () =>
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Email: ${widget.otherUserEmail}',
                  style: const TextStyle(fontFamily: 'Raleway')),
              backgroundColor: primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            )),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isMe = msg.senderUid == _myUid;
              return StaggeredItem(
                index: index % 10,
                delayMs: 30,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: widget.avatarColor.withOpacity(0.12),
                          child: Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.avatarColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? primary : bgCard,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.text,
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        color: isMe ? Colors.white : textDark,
                                        height: 1.4)),
                                const SizedBox(height: 4),
                                Text(_formatTime(msg.createdAt),
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white.withOpacity(0.6)
                                            : textLight)),
                              ]),
                        ),
                      ),
                      if (isMe) const SizedBox(width: 4),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bgCard,
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4))
            ],
          ),
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(
                          fontFamily: 'Raleway', fontSize: 14, color: textDark),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 13,
                            color: textLight),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BouncyTap(
                  onTap: _sending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _sending ? primary.withOpacity(0.5) : primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ])),
        ),
      ]),
    );
  }
}
