class ActivityModel {
  final String name;
  final String imageUrl;
  final bool isYou;

  const ActivityModel({
    required this.name,
    required this.imageUrl,
    this.isYou = false,
  });
}

class MessageModel {
  final String name;
  final String message;
  final String image;
  final String timestamp;
  final int unreadCount;

  const MessageModel({
    required this.name,
    required this.message,
    required this.image,
    required this.timestamp,
    this.unreadCount = 0,
  });

  Map<String, String> toMap() => {
    'name': name,
    'message': message,
    'image': image,
    'timestamp': timestamp,
  };
}