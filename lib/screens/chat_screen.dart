import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/firestore_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final User currentUser;
  final User otherUser;
  ChatScreen({required this.currentUser, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _load() async {
    await FirestoreService.instance.markMessagesAsRead(
        widget.otherUser.username, widget.currentUser.username);
    final msgs = await FirestoreService.instance.getConversation(
        widget.currentUser.username, widget.otherUser.username);
    setState(() => _messages = msgs);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final msg = Message(
      senderUsername: widget.currentUser.username,
      receiverUsername: widget.otherUser.username,
      text: text,
      date: now,
    );
    await FirestoreService.instance.createMessage(msg);
    _ctrl.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: brand.withValues(alpha: 0.2),
              backgroundImage: widget.otherUser.profileImagePath.isNotEmpty
                  ? FileImage(File(widget.otherUser.profileImagePath))
                  : null,
              child: widget.otherUser.profileImagePath.isEmpty
                  ? Icon(Icons.person, color: brand, size: 18)
                  : null,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.displayName ?? widget.otherUser.username,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('@${widget.otherUser.username}',
                      style: TextStyle(fontSize: 12, color: secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('Envíale un mensaje', style: TextStyle(color: secondaryText)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderUsername == widget.currentUser.username;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(
                            top: 4,
                            bottom: 4,
                            left: isMe ? 60 : 0,
                            right: isMe ? 0 : 60,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? brand
                                : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                              bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : null,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                msg.date.length > 10 ? msg.date.substring(11) : msg.date,
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : secondaryText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 12, right: 8, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Mensaje...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: brand,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
