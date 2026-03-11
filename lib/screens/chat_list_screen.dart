import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final User currentUser;
  ChatListScreen({required this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  List<User> _allUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final chats = await DatabaseHelper.instance.getChatList(widget.currentUser.username);
    final users = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      _chats = chats;
      _allUsers = users.where((u) => u.username != widget.currentUser.username).toList();
    });
  }

  void _openChat(User user) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(currentUser: widget.currentUser, otherUser: user),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter users by search
    final filteredUsers = _searchQuery.isEmpty
        ? <User>[]
        : _allUsers.where((u) =>
            u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (u.displayName ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: Icon(Icons.search, color: brand),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Search results
        if (_searchQuery.isNotEmpty) ...[
          if (filteredUsers.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se encontraron usuarios', style: TextStyle(color: secondaryText)),
            )
          else
            ...filteredUsers.map((user) => ListTile(
              leading: CircleAvatar(
                backgroundColor: brand.withValues(alpha: 0.2),
                backgroundImage: user.profileImagePath.isNotEmpty
                    ? FileImage(File(user.profileImagePath))
                    : null,
                child: user.profileImagePath.isEmpty
                    ? Icon(Icons.person, color: brand)
                    : null,
              ),
              title: Text(user.username, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.displayName ?? '', style: TextStyle(color: secondaryText)),
              onTap: () {
                setState(() => _searchQuery = '');
                _openChat(user);
              },
            )),
          Divider(),
        ],

        // Chat list
        Expanded(
          child: _chats.isEmpty && _searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: secondaryText),
                      SizedBox(height: 12),
                      Text('No hay conversaciones', style: TextStyle(color: secondaryText, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Busca un usuario para empezar a chatear', style: TextStyle(color: secondaryText, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, i) {
                    final chat = _chats[i];
                    final user = chat['user'] as User;
                    final lastMsg = chat['lastMessage'] as Message;
                    final unread = chat['unread'] as int;

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: brand.withValues(alpha: 0.2),
                            backgroundImage: user.profileImagePath.isNotEmpty
                                ? FileImage(File(user.profileImagePath))
                                : null,
                            child: user.profileImagePath.isEmpty
                                ? Icon(Icons.person, color: brand)
                                : null,
                          ),
                        ],
                      ),
                      title: Text(user.displayName ?? user.username, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        lastMsg.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0 ? null : secondaryText,
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(lastMsg.date.length > 10 ? lastMsg.date.substring(11) : lastMsg.date,
                              style: TextStyle(color: secondaryText, fontSize: 11)),
                          if (unread > 0) ...[
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
                              child: Text('$unread', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _openChat(user),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
