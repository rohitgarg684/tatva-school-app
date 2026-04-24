import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/group_conversation.dart';
import '../../repositories/auth_repository.dart';
import '../../services/group_message_service.dart';
import '../../shared/theme/colors.dart';

class GroupMessagingScreen extends StatefulWidget {
  final GroupConversation group;

  const GroupMessagingScreen({super.key, required this.group});

  @override
  State<GroupMessagingScreen> createState() => _GroupMessagingScreenState();
}

class _GroupMessagingScreenState extends State<GroupMessagingScreen> {
  final _msgSvc = GroupMessageService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late String _myUid;
  List<MessageModel> _messages = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _myUid = AuthRepository().currentUid ?? '';
    _subscription = _msgSvc.getMessages(widget.group.id).listen((msgs) {
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msg = MessageModel(
      text: text,
      senderUid: _myUid,
      receiverUid: '',
      conversationId: widget.group.id,
    );

    await _msgSvc.sendMessage(widget.group.id, msg, 'You');
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.className,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${widget.group.memberUids.length} members',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: TatvaColors.textDark,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('No messages yet. Start the conversation!',
                        style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderUid == _myUid;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe
                                ? TatvaColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(msg.senderUid,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: TatvaColors.primary)),
                              Text(msg.text,
                                  style: TextStyle(
                                      color: isMe ? Colors.white : TatvaColors.textDark,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(_formatTime(msg.createdAt),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, -1))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: TatvaColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
