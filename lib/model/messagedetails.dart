enum MessageStatus {
  sent,
  delivered,
  read,
}

class ChatMessage {

  final String text;

  final bool isMe;

  final String time;

  final MessageStatus status;

  final bool isImage;
  final bool isVideo;



  const ChatMessage({

    required this.text,

    required this.isMe,

    required this.time,

    this.status = MessageStatus.read,

    this.isImage = false,

    this.isVideo = false,


  });
}