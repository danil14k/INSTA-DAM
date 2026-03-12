class Message {
  String? id;
  String senderUsername;
  String receiverUsername;
  String text;
  String date;
  bool read;

  Message({
    this.id,
    required this.senderUsername,
    required this.receiverUsername,
    required this.text,
    required this.date,
    this.read = false,
  });

  Map<String, dynamic> toMap() => {
        'senderUsername': senderUsername,
        'receiverUsername': receiverUsername,
        'text': text,
        'date': date,
        'read': read,
      };

  factory Message.fromMap(Map<String, dynamic> m, {String? docId}) => Message(
        id: docId ?? m['id']?.toString(),
        senderUsername: m['senderUsername'],
        receiverUsername: m['receiverUsername'],
        text: m['text'],
        date: m['date'],
        read: m['read'] is bool ? m['read'] : (m['read'] ?? 0) == 1,
      );
}
