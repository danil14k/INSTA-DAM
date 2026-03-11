import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';

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
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ""');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        displayName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imageUrl TEXT,
        username TEXT,
        description TEXT,
        date TEXT,
        likes INTEGER
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
  }

  // Users
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

  // Posts
  Future<Post> createPost(Post p) async {
    final db = await instance.database;
    p.id = await db.insert('posts', p.toMap());
    return p;
  }

  Future<List<Post>> getAllPosts({String? username}) async {
    final db = await instance.database;
    final res = username == null ? await db.query('posts', orderBy: 'id DESC') : await db.query('posts', where: 'username=?', whereArgs: [username], orderBy: 'id DESC');
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
    return await db.delete('posts', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updatePostLikes(int postId, int likes) async {
    final db = await instance.database;
    return await db.update('posts', {'likes': likes}, where: 'id=?', whereArgs: [postId]);
  }

  // Likes - track per-user likes so UI can show immediate per-user state
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

  // Comments
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
}
