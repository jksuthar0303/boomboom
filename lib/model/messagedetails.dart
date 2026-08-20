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
  final bool isUploading;
  final String? localFilePath;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.status = MessageStatus.read,
    this.isImage = false,
    this.isVideo = false,
    this.isUploading = false,
    this.localFilePath,
  });

  ChatMessage copyWith({
    String? text,
    bool? isMe,
    String? time,
    MessageStatus? status,
    bool? isImage,
    bool? isVideo,
    bool? isUploading,
    String? localFilePath,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      time: time ?? this.time,
      status: status ?? this.status,
      isImage: isImage ?? this.isImage,
      isVideo: isVideo ?? this.isVideo,
      isUploading: isUploading ?? this.isUploading,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}