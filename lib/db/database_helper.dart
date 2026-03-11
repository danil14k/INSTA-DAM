import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('instadam.db');
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);
    return await openDatabase(path, version: 5, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE posts ADD COLUMN mediaPath TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE posts ADD COLUMN mediaType TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE users ADD COLUMN profileImagePath TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE posts ADD COLUMN location TEXT NOT NULL DEFAULT ""');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS follows(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          followerUsername TEXT,
          followingUsername TEXT,
          UNIQUE(followerUsername, followingUsername)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          senderUsername TEXT,
          receiverUsername TEXT,
          text TEXT,
          date TEXT,
          read INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bookmarks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          postId INTEGER,
          username TEXT,
          UNIQUE(postId, username)
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        displayName TEXT,
        bio TEXT DEFAULT '',
        profileImagePath TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imageUrl TEXT,
        username TEXT,
        description TEXT,
        date TEXT,
        likes INTEGER,
        mediaPath TEXT,
        mediaType TEXT,
        location TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        username TEXT,
        text TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE likes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        username TEXT,
        UNIQUE(postId, username)
      )
    ''');

    await db.execute('''
      CREATE TABLE follows(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        followerUsername TEXT,
        followingUsername TEXT,
        UNIQUE(followerUsername, followingUsername)
      )
    ''');

    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderUsername TEXT,
        receiverUsername TEXT,
        text TEXT,
        date TEXT,
        read INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        username TEXT,
        UNIQUE(postId, username)
      )
    ''');
  }

  // ==================== Users ====================
  Future<User> createUser(User user) async {
    final db = await instance.database;
    user.id = await db.insert('users', user.toMap());
    return user;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'username=?', whereArgs: [username]);
    if (res.isNotEmpty) return User.fromMap(res.first);
    return null;
  }

  Future<User?> login(String username, String password) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'username=? AND password=?', whereArgs: [username, password]);
    if (res.isNotEmpty) return User.fromMap(res.first);
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update('users', user.toMap(), where: 'id=?', whereArgs: [user.id]);
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final res = await db.query('users', orderBy: 'username ASC');
    return res.map((m) => User.fromMap(m)).toList();
  }

  Future<List<User>> searchUsers(String query) async {
    final db = await instance.database;
    final res = await db.query('users',
        where: 'username LIKE ? OR displayName LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'username ASC');
    return res.map((m) => User.fromMap(m)).toList();
  }

  // ==================== Posts ====================
  Future<Post> createPost(Post p) async {
    final db = await instance.database;
    p.id = await db.insert('posts', p.toMap());
    return p;
  }

  Future<List<Post>> getAllPosts({String? username}) async {
    final db = await instance.database;
    final res = username == null
        ? await db.query('posts', orderBy: 'id DESC')
        : await db.query('posts', where: 'username=?', whereArgs: [username], orderBy: 'id DESC');
    return res.map((m) => Post.fromMap(m)).toList();
  }

  Future<List<Post>> getMediaPosts() async {
    final db = await instance.database;
    final res = await db.query('posts',
        where: 'mediaPath IS NOT NULL AND mediaPath != ""',
        orderBy: 'id DESC');
    return res.map((m) => Post.fromMap(m)).toList();
  }

  Future<int> updatePost(Post p) async {
    final db = await instance.database;
    return await db.update('posts', p.toMap(), where: 'id=?', whereArgs: [p.id]);
  }

  Future<int> deletePost(int id) async {
    final db = await instance.database;
    await db.delete('likes', where: 'postId=?', whereArgs: [id]);
    await db.delete('comments', where: 'postId=?', whereArgs: [id]);
    await db.delete('bookmarks', where: 'postId=?', whereArgs: [id]);
    return await db.delete('posts', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updatePostLikes(int postId, int likes) async {
    final db = await instance.database;
    return await db.update('posts', {'likes': likes}, where: 'id=?', whereArgs: [postId]);
  }

  // ==================== Likes ====================
  Future<void> addLike(int postId, String username) async {
    final db = await instance.database;
    await db.insert('likes', {'postId': postId, 'username': username}, conflictAlgorithm: ConflictAlgorithm.ignore);
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM likes WHERE postId=?', [postId]);
    final count = Sqflite.firstIntValue(res) ?? 0;
    await updatePostLikes(postId, count);
  }

  Future<void> removeLike(int postId, String username) async {
    final db = await instance.database;
    await db.delete('likes', where: 'postId=? AND username=?', whereArgs: [postId, username]);
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM likes WHERE postId=?', [postId]);
    final count = Sqflite.firstIntValue(res) ?? 0;
    await updatePostLikes(postId, count);
  }

  Future<bool> isPostLikedBy(int postId, String username) async {
    final db = await instance.database;
    final res = await db.query('likes', where: 'postId=? AND username=?', whereArgs: [postId, username]);
    return res.isNotEmpty;
  }

  Future<int> countLikesForPost(int postId) async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM likes WHERE postId=?', [postId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ==================== Bookmarks ====================
  Future<void> addBookmark(int postId, String username) async {
    final db = await instance.database;
    await db.insert('bookmarks', {'postId': postId, 'username': username}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeBookmark(int postId, String username) async {
    final db = await instance.database;
    await db.delete('bookmarks', where: 'postId=? AND username=?', whereArgs: [postId, username]);
  }

  Future<bool> isPostBookmarkedBy(int postId, String username) async {
    final db = await instance.database;
    final res = await db.query('bookmarks', where: 'postId=? AND username=?', whereArgs: [postId, username]);
    return res.isNotEmpty;
  }

  // ==================== Comments ====================
  Future<Comment> createComment(Comment c) async {
    final db = await instance.database;
    c.id = await db.insert('comments', c.toMap());
    return c;
  }

  Future<List<Comment>> getCommentsForPost(int postId) async {
    final db = await instance.database;
    final res = await db.query('comments', where: 'postId=?', whereArgs: [postId], orderBy: 'id DESC');
    return res.map((m) => Comment.fromMap(m)).toList();
  }

  Future<int> countCommentsForPost(int postId) async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM comments WHERE postId=?', [postId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ==================== Follows ====================
  Future<void> followUser(String follower, String following) async {
    final db = await instance.database;
    await db.insert('follows', {
      'followerUsername': follower,
      'followingUsername': following,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> unfollowUser(String follower, String following) async {
    final db = await instance.database;
    await db.delete('follows',
        where: 'followerUsername=? AND followingUsername=?',
        whereArgs: [follower, following]);
  }

  Future<bool> isFollowing(String follower, String following) async {
    final db = await instance.database;
    final res = await db.query('follows',
        where: 'followerUsername=? AND followingUsername=?',
        whereArgs: [follower, following]);
    return res.isNotEmpty;
  }

  Future<int> getFollowersCount(String username) async {
    final db = await instance.database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) as c FROM follows WHERE followingUsername=?', [username]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getFollowingCount(String username) async {
    final db = await instance.database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) as c FROM follows WHERE followerUsername=?', [username]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<User>> getFollowers(String username) async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN follows f ON f.followerUsername = u.username
      WHERE f.followingUsername = ?
      ORDER BY u.username ASC
    ''', [username]);
    return res.map((m) => User.fromMap(m)).toList();
  }

  Future<List<User>> getFollowing(String username) async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN follows f ON f.followingUsername = u.username
      WHERE f.followerUsername = ?
      ORDER BY u.username ASC
    ''', [username]);
    return res.map((m) => User.fromMap(m)).toList();
  }

  // ==================== Messages ====================
  Future<Message> createMessage(Message m) async {
    final db = await instance.database;
    m.id = await db.insert('messages', m.toMap());
    return m;
  }

  Future<List<Message>> getConversation(String user1, String user2) async {
    final db = await instance.database;
    final res = await db.query('messages',
        where: '(senderUsername=? AND receiverUsername=?) OR (senderUsername=? AND receiverUsername=?)',
        whereArgs: [user1, user2, user2, user1],
        orderBy: 'id ASC');
    return res.map((m) => Message.fromMap(m)).toList();
  }

  /// Returns list of users the current user has chatted with, with the last message
  Future<List<Map<String, dynamic>>> getChatList(String username) async {
    final db = await instance.database;
    // Get distinct conversation partners
    final res = await db.rawQuery('''
      SELECT DISTINCT
        CASE WHEN senderUsername = ? THEN receiverUsername ELSE senderUsername END as partner
      FROM messages
      WHERE senderUsername = ? OR receiverUsername = ?
    ''', [username, username, username]);

    List<Map<String, dynamic>> chats = [];
    for (final row in res) {
      final partner = row['partner'] as String;
      final lastMsg = await db.query('messages',
          where: '(senderUsername=? AND receiverUsername=?) OR (senderUsername=? AND receiverUsername=?)',
          whereArgs: [username, partner, partner, username],
          orderBy: 'id DESC',
          limit: 1);
      final unread = await db.rawQuery(
          'SELECT COUNT(*) as c FROM messages WHERE senderUsername=? AND receiverUsername=? AND read=0',
          [partner, username]);
      final unreadCount = Sqflite.firstIntValue(unread) ?? 0;
      final user = await getUserByUsername(partner);
      if (lastMsg.isNotEmpty && user != null) {
        chats.add({
          'user': user,
          'lastMessage': Message.fromMap(lastMsg.first),
          'unread': unreadCount,
        });
      }
    }
    // Sort by last message id desc
    chats.sort((a, b) => (b['lastMessage'] as Message).id!.compareTo((a['lastMessage'] as Message).id!));
    return chats;
  }

  Future<void> markMessagesAsRead(String sender, String receiver) async {
    final db = await instance.database;
    await db.update('messages', {'read': 1},
        where: 'senderUsername=? AND receiverUsername=? AND read=0',
        whereArgs: [sender, receiver]);
  }
}
