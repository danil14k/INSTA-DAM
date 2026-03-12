import 'dart:io';
import 'package:flutter/material.dart';
import '../db/firestore_service.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class MentionUsersScreen extends StatefulWidget {
  final String currentUsername;
  final List<String> alreadyMentioned;
  MentionUsersScreen({required this.currentUsername, this.alreadyMentioned = const []});

  @override
  State<MentionUsersScreen> createState() => _MentionUsersScreenState();
}

class _MentionUsersScreenState extends State<MentionUsersScreen> {
  List<User> _users = [];
  List<String> _selected = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.alreadyMentioned);
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await FirestoreService.instance.getAllUsers();
    setState(() {
      _users = users.where((u) => u.username != widget.currentUsername).toList();
    });
  }

  List<User> get _filtered {
    if (_query.isEmpty) return _users;
    return _users.where((u) =>
        u.username.toLowerCase().contains(_query.toLowerCase()) ||
        (u.displayName ?? '').toLowerCase().contains(_query.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Etiquetar personas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: brand),
            onPressed: () => Navigator.pop(context, _selected),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: Icon(Icons.search, color: brand),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_selected.isNotEmpty)
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selected.map((u) => Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('@$u'),
                    deleteIcon: Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selected.remove(u)),
                    backgroundColor: brand.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: brand, fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final user = _filtered[i];
                final isSelected = _selected.contains(user.username);
                return ListTile(
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
                  subtitle: Text(user.displayName ?? ''),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: brand)
                      : Icon(Icons.circle_outlined, color: Theme.of(context).textTheme.bodyMedium?.color),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(user.username);
                      } else {
                        _selected.add(user.username);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
