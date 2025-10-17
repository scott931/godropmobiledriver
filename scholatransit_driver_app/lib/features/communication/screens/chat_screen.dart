import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/services/communication_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final bool _isTyping = false;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markChatAsRead();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.getChatDetails(
        chatId: widget.conversation.id,
      );
      if (response.success && response.data != null) {
        final chatData = response.data!;
        final messagesList =
            (chatData['messages'] as List?)
                ?.map((message) => Message.fromJson(message))
                .toList() ??
            [];

        setState(() {
          _messages.clear();
          _messages.addAll(messagesList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markChatAsRead() async {
    try {
      await CommunicationService.markChatAsRead(chatId: widget.conversation.id);
    } catch (e) {
      // Silently handle read receipt errors
      print('Failed to mark chat as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Optimistically add message to UI
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      conversationId: widget.conversation.id,
      senderId: 999, // Current user
      senderName: "You",
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
    });

    _scrollToBottom();

    try {
      final response = await CommunicationService.sendTextMessage(
        chatId: widget.conversation.id,
        content: content,
      );

      if (response.success && response.data != null) {
        // Replace temp message with real message from server
        final realMessage = Message.fromJson(response.data!);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (index != -1) {
            _messages[index] = realMessage;
          }
        });
      } else {
        // Remove temp message on failure
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to send message')),
          );
        }
      }
    } catch (e) {
      // Remove temp message on error
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/conversations');
            }
          },
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
          Expanded(child: _buildMessagesList()),
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

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.w, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                _error!,
                style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadMessages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return const TypingIndicator();
        }

        final message = _messages[index];
        final isMe = message.senderId == 999;

        return _buildMessageBubble(message, isMe);
      },
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

    return MessageBubble(message: message, isMe: isMe);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
