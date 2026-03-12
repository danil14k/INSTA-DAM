import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/message.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  FirestoreService._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colecciones
  CollectionReference get _users => _db.collection('usuarios');
  CollectionReference get _posts => _db.collection('posts');
  CollectionReference get _comments => _db.collection('comentarios');
  CollectionReference get _likes => _db.collection('likes');
  CollectionReference get _follows => _db.collection('follows');
  CollectionReference get _messages => _db.collection('messages');
  CollectionReference get _bookmarks => _db.collection('bookmarks');

  // ==================== Users ====================
  Future<User> createUser(User user) async {
    final doc = await _users.add(user.toMap());
    user.id = doc.id;
    return user;
  }

  Future<User?> getUserByUsername(String username) async {
    final snap = await _users.where('username', isEqualTo: username).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return User.fromMap(snap.docs.first.data() as Map<String, dynamic>, docId: snap.docs.first.id);
    }
    return null;
  }

  Future<User?> login(String username, String password) async {
    final snap = await _users
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return User.fromMap(snap.docs.first.data() as Map<String, dynamic>, docId: snap.docs.first.id);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    if (user.id == null) return;
    await _users.doc(user.id).update(user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final snap = await _users.orderBy('username').get();
    return snap.docs.map((d) => User.fromMap(d.data() as Map<String, dynamic>, docId: d.id)).toList();
  }

  Future<List<User>> searchUsers(String query) async {
    // Firestore no soporta LIKE, hacemos búsqueda por prefijo en username
    final snap = await _users
        .orderBy('username')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();
    return snap.docs.map((d) => User.fromMap(d.data() as Map<String, dynamic>, docId: d.id)).toList();
  }

  // ==================== Posts ====================
  Future<Post> createPost(Post p) async {
    final doc = await _posts.add(p.toMap());
    p.id = doc.id;
    return p;
  }

  Future<List<Post>> getAllPosts({String? username}) async {
    Query query = _posts.orderBy('date', descending: true);
    if (username != null) {
      query = query.where('username', isEqualTo: username);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Post.fromMap(d.data() as Map<String, dynamic>, docId: d.id)).toList();
  }

  Future<List<Post>> getMediaPosts() async {
    final snap = await _posts
        .where('mediaPath', isNotEqualTo: '')
        .orderBy('mediaPath')
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => Post.fromMap(d.data() as Map<String, dynamic>, docId: d.id))
        .where((p) => p.hasMedia)
        .toList();
  }

  Future<void> updatePost(Post p) async {
    if (p.id == null) return;
    await _posts.doc(p.id).update(p.toMap());
  }

  Future<void> deletePost(String postId) async {
    // Eliminar likes, comentarios y bookmarks asociados
    final likesSnap = await _likes.where('postId', isEqualTo: postId).get();
    for (final doc in likesSnap.docs) await doc.reference.delete();

    final commentsSnap = await _comments.where('postId', isEqualTo: postId).get();
    for (final doc in commentsSnap.docs) await doc.reference.delete();

    final bookmarksSnap = await _bookmarks.where('postId', isEqualTo: postId).get();
    for (final doc in bookmarksSnap.docs) await doc.reference.delete();

    await _posts.doc(postId).delete();
  }

  Future<void> updatePostLikes(String postId, int likes) async {
    await _posts.doc(postId).update({'likes': likes});
  }

  // ==================== Likes ====================
  Future<void> addLike(String postId, String username) async {
    final id = '${postId}_$username';
    await _likes.doc(id).set({'postId': postId, 'username': username});
    final count = await countLikesForPost(postId);
    await updatePostLikes(postId, count);
  }

  Future<void> removeLike(String postId, String username) async {
    final id = '${postId}_$username';
    await _likes.doc(id).delete();
    final count = await countLikesForPost(postId);
    await updatePostLikes(postId, count);
  }

  Future<bool> isPostLikedBy(String postId, String username) async {
    final id = '${postId}_$username';
    final doc = await _likes.doc(id).get();
    return doc.exists;
  }

  Future<int> countLikesForPost(String postId) async {
    final snap = await _likes.where('postId', isEqualTo: postId).get();
    return snap.docs.length;
  }

  // ==================== Bookmarks ====================
  Future<void> addBookmark(String postId, String username) async {
    final id = '${postId}_$username';
    await _bookmarks.doc(id).set({'postId': postId, 'username': username});
  }

  Future<void> removeBookmark(String postId, String username) async {
    final id = '${postId}_$username';
    await _bookmarks.doc(id).delete();
  }

  Future<bool> isPostBookmarkedBy(String postId, String username) async {
    final id = '${postId}_$username';
    final doc = await _bookmarks.doc(id).get();
    return doc.exists;
  }

  // ==================== Comments ====================
  Future<Comment> createComment(Comment c) async {
    final doc = await _comments.add(c.toMap());
    c.id = doc.id;
    return c;
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    final snap = await _comments
        .where('postId', isEqualTo: postId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => Comment.fromMap(d.data() as Map<String, dynamic>, docId: d.id)).toList();
  }

  Future<int> countCommentsForPost(String postId) async {
    final snap = await _comments.where('postId', isEqualTo: postId).get();
    return snap.docs.length;
  }

  // ==================== Follows ====================
  Future<void> followUser(String follower, String following) async {
    final id = '${follower}_$following';
    await _follows.doc(id).set({
      'followerUsername': follower,
      'followingUsername': following,
    });
  }

  Future<void> unfollowUser(String follower, String following) async {
    final id = '${follower}_$following';
    await _follows.doc(id).delete();
  }

  Future<bool> isFollowing(String follower, String following) async {
    final id = '${follower}_$following';
    final doc = await _follows.doc(id).get();
    return doc.exists;
  }

  Future<int> getFollowersCount(String username) async {
    final snap = await _follows.where('followingUsername', isEqualTo: username).get();
    return snap.docs.length;
  }

  Future<int> getFollowingCount(String username) async {
    final snap = await _follows.where('followerUsername', isEqualTo: username).get();
    return snap.docs.length;
  }

  Future<List<User>> getFollowers(String username) async {
    final snap = await _follows.where('followingUsername', isEqualTo: username).get();
    List<User> users = [];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final user = await getUserByUsername(data['followerUsername']);
      if (user != null) users.add(user);
    }
    users.sort((a, b) => a.username.compareTo(b.username));
    return users;
  }

  Future<List<User>> getFollowing(String username) async {
    final snap = await _follows.where('followerUsername', isEqualTo: username).get();
    List<User> users = [];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final user = await getUserByUsername(data['followingUsername']);
      if (user != null) users.add(user);
    }
    users.sort((a, b) => a.username.compareTo(b.username));
    return users;
  }

  // ==================== Messages ====================
  Future<Message> createMessage(Message m) async {
    final doc = await _messages.add(m.toMap());
    m.id = doc.id;
    return m;
  }

  Future<List<Message>> getConversation(String user1, String user2) async {
    // Firestore no soporta OR directamente, hacemos 2 queries
    final snap1 = await _messages
        .where('senderUsername', isEqualTo: user1)
        .where('receiverUsername', isEqualTo: user2)
        .get();
    final snap2 = await _messages
        .where('senderUsername', isEqualTo: user2)
        .where('receiverUsername', isEqualTo: user1)
        .get();

    final allDocs = [...snap1.docs, ...snap2.docs];
    final messages = allDocs
        .map((d) => Message.fromMap(d.data() as Map<String, dynamic>, docId: d.id))
        .toList();
    messages.sort((a, b) => a.date.compareTo(b.date));
    return messages;
  }

  Future<List<Map<String, dynamic>>> getChatList(String username) async {
    final snap1 = await _messages.where('senderUsername', isEqualTo: username).get();
    final snap2 = await _messages.where('receiverUsername', isEqualTo: username).get();

    Set<String> partners = {};
    for (final doc in snap1.docs) {
      final data = doc.data() as Map<String, dynamic>;
      partners.add(data['receiverUsername']);
    }
    for (final doc in snap2.docs) {
      final data = doc.data() as Map<String, dynamic>;
      partners.add(data['senderUsername']);
    }

    List<Map<String, dynamic>> chats = [];
    for (final partner in partners) {
      final conversation = await getConversation(username, partner);
      if (conversation.isEmpty) continue;

      final lastMessage = conversation.last;

      // Contar mensajes no leídos
      final unreadSnap = await _messages
          .where('senderUsername', isEqualTo: partner)
          .where('receiverUsername', isEqualTo: username)
          .where('read', isEqualTo: false)
          .get();
      final unreadCount = unreadSnap.docs.length;

      final user = await getUserByUsername(partner);
      if (user != null) {
        chats.add({
          'user': user,
          'lastMessage': lastMessage,
          'unread': unreadCount,
        });
      }
    }
    chats.sort((a, b) => (b['lastMessage'] as Message).date.compareTo((a['lastMessage'] as Message).date));
    return chats;
  }

  Future<void> markMessagesAsRead(String sender, String receiver) async {
    final snap = await _messages
        .where('senderUsername', isEqualTo: sender)
        .where('receiverUsername', isEqualTo: receiver)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'read': true});
    }
  }
}
