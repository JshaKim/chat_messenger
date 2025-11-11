import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File) onSendImage;
  final bool isSending;

  const ChatInputField({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    this.isSending = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSendText(text);
      _textController.clear();
    }
  }

  Future<void> _handlePickImage() async {
    if (widget.isSending) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        widget.onSendImage(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택할 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 이미지 선택 버튼
            IconButton(
              icon: const Icon(Icons.image),
              color: Colors.grey[700],
              onPressed: widget.isSending ? null : _handlePickImage,
            ),
            // 텍스트 입력 필드
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendText(),
                enabled: !widget.isSending,
              ),
            ),
            const SizedBox(width: 8),
            // 전송 버튼
            widget.isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFEE500),
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _hasText
                          ? const Color(0xFFFEE500)
                          : Colors.grey[400],
                    ),
                    onPressed: _hasText ? _handleSendText : null,
                  ),
          ],
        ),
      ),
    );
  }
}
