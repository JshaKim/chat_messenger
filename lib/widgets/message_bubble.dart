import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            // 읽음 표시
            if (!message.isRead)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFFEE500),
                  ),
                ),
              ),
            // 시간
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(width: 4),
          ],
          // 메시지 내용
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFEE500) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.imageUrl != null
                  ? _buildImageMessage()
                  : _buildTextMessage(),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            // 시간
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextMessage() {
    return Text(
      message.text,
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: message.imageUrl!,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }
}
