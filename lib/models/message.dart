class Message {
  int? id;
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
        'id': id,
        'senderUsername': senderUsername,
        'receiverUsername': receiverUsername,
        'text': text,
        'date': date,
        'read': read ? 1 : 0,
      };

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        id: m['id'],
        senderUsername: m['senderUsername'],
        receiverUsername: m['receiverUsername'],
        text: m['text'],
        date: m['date'],
        read: (m['read'] ?? 0) == 1,
      );
}
