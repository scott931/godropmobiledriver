import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/conversation_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    // Sample messages to match the image
    setState(() {
      _messages.addAll([
        Message(
          id: 1,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "Hello!",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        Message(
          id: 2,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "How are you?",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
        Message(
          id: 3,
          conversationId: widget.conversation.id,
          senderId: 999, // Current user
          senderName: "You",
          content: "Good .. Dude , Thanks",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        Message(
          id: 4,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "Please send me the lastest report",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
        ),
        Message(
          id: 5,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "Ps:Thanks :)",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
        Message(
          id: 6,
          conversationId: widget.conversation.id,
          senderId: 999, // Current user
          senderName: "You",
          content: "", // Voice message
          type: MessageType.voice,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          voiceUrl: "sample_voice_url",
          voiceDuration: 15,
        ),
        Message(
          id: 7,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "", // Voice message
          type: MessageType.voice,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          voiceUrl: "sample_voice_url",
          voiceDuration: 12,
        ),
        Message(
          id: 8,
          conversationId: widget.conversation.id,
          senderId: widget.conversation.studentId,
          senderName: widget.conversation.studentName,
          senderAvatar: widget.conversation.studentAvatar,
          content: "Hello dude",
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ]);
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = Message(
      id: _messages.length + 1,
      conversationId: widget.conversation.id,
      senderId: 999, // Current user
      senderName: "You",
      content: _messageController.text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate typing indicator
    _showTypingIndicator();
  }

  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundImage: widget.conversation.studentAvatar != null
                  ? NetworkImage(widget.conversation.studentAvatar!)
                  : null,
              child: widget.conversation.studentAvatar == null
                  ? Text(
                      widget.conversation.studentName.isNotEmpty
                          ? widget.conversation.studentName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.studentName,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Active Now',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: () {
              // Handle phone call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            onPressed: () {
              // Handle video call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const TypingIndicator();
                }

                final message = _messages[index];
                final isMe = message.senderId == 999;

                // Add date separator for Friday 12, 2023
                if (index == 6) {
                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16.h),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Friday 12, 2023',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      _buildMessageBubble(message, isMe),
                    ],
                  );
                }

                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          ChatInputField(
            controller: _messageController,
            onSend: _sendMessage,
            onVoiceRecord: _startVoiceRecording,
            onVoiceStop: _stopVoiceRecording,
            isRecording: _isRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    if (message.type == MessageType.voice) {
      return VoiceMessageBubble(
        message: message,
        isMe: isMe,
        onPlay: () {
          // Handle voice message play
        },
      );
    }

    return MessageBubble(
      message: message,
      isMe: isMe,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
