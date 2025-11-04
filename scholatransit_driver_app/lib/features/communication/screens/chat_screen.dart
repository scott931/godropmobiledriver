import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/models/message_model.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/realtime_update_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/image_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/recording_indicator.dart';

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
  Conversation? _chatDetails;
  int? _currentUserId;
  final bool _isTyping = false;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _error;
  final Record _audioRecorder = Record();
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadChatDetails();
    _markChatAsRead();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    // Set current chat to prevent notifications when viewing
    RealtimeUpdateService.setCurrentChat(widget.conversation.id);

    // Start real-time polling for this chat
    RealtimeUpdateService.startPolling(
      chatId: widget.conversation.id,
      onNewMessages: (newMessages) {
        // Add new messages to the list
        setState(() {
          for (final message in newMessages) {
            // Avoid duplicates
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
            }
          }
          // Sort messages by timestamp
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        _scrollToBottom();
      },
      onChatMessagesUpdated: (chatId, updatedMessages) {
        if (chatId == widget.conversation.id) {
          setState(() {
            for (final message in updatedMessages) {
              // Update existing message or add new one
              final index = _messages.indexWhere((m) => m.id == message.id);
              if (index >= 0) {
                // Update message (this handles both new messages and read status updates)
                _messages[index] = message;
                print('🔄 Updated message ${message.id} - isRead: ${message.isRead}');
              } else {
                // Add new message
                _messages.add(message);
                print('➕ Added new message ${message.id}');
              }
            }
            // Sort messages by timestamp
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });

          // Update last message ID if we have new messages
          if (updatedMessages.isNotEmpty) {
            final latestMessage = updatedMessages.reduce((a, b) =>
              a.id > b.id ? a : b
            );
            RealtimeUpdateService.initializeChatLastMessage(
              widget.conversation.id,
              latestMessage.id,
            );
          }
        }
      },
    );
  }

  void _getCurrentUserId() {
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      _currentUserId = profile['id'] as int?;
      print('🔍 DEBUG: Current User ID set to: $_currentUserId');
    } else {
      print('⚠️ WARNING: User profile not found, _currentUserId is null');
    }
  }

  Future<void> _loadChatDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.getChatDetails(
        chatId: widget.conversation.id,
      );
      if (response.success && response.data != null) {
        // Handle both direct Map and wrapped response
        Map<String, dynamic> chatData;
        if (response.data is Map<String, dynamic>) {
          chatData = response.data as Map<String, dynamic>;
          // Check if it's wrapped (has 'data' or 'results' key)
          if (chatData.containsKey('data') && chatData['data'] is Map<String, dynamic>) {
            chatData = chatData['data'] as Map<String, dynamic>;
          }
        } else {
          // Fallback - create empty chat data
          chatData = {'id': widget.conversation.id};
        }

        // Debug: Log the structure before parsing
        print('🔍 DEBUG: Chat data structure - messages type: ${chatData['messages']?.runtimeType}');
        if (chatData['messages'] is List) {
          final msgs = chatData['messages'] as List;
          if (msgs.isNotEmpty) {
            print('🔍 DEBUG: First message item type: ${msgs.first.runtimeType}');
            print('🔍 DEBUG: First message item: ${msgs.first}');
          }
        }

        final chat = Conversation.fromJson(chatData);
        var messagesList = chat.messages ?? [];

        // If no messages in chat details, try loading them separately
        if (messagesList.isEmpty) {
          try {
            final messagesResponse = await CommunicationService.getChatMessages(
              chatId: widget.conversation.id,
            );

            if (messagesResponse.success && messagesResponse.data != null) {
              // Handle both direct List and wrapped response
              List<dynamic> messagesData;
              if (messagesResponse.data is List) {
                messagesData = messagesResponse.data as List;
              } else if (messagesResponse.data is Map<String, dynamic>) {
                final data = messagesResponse.data as Map<String, dynamic>;
                if (data.containsKey('results')) {
                  messagesData = data['results'] as List? ?? [];
                } else if (data.containsKey('data')) {
                  messagesData = data['data'] as List? ?? [];
                } else {
                  messagesData = [];
                }
              } else {
                messagesData = [];
              }

              messagesList = messagesData
                  .where((m) => m != null && m is Map<String, dynamic>)
                  .map((m) {
                    try {
                      return Message.fromJson(m as Map<String, dynamic>);
                    } catch (e) {
                      print('Error parsing message: $e, data: $m');
                      return null;
                    }
                  })
                  .whereType<Message>() // Remove nulls from failed parsing
                  .toList();
            }
          } catch (e) {
            // Silently handle - messages might not be available separately
            print('Could not load messages separately: $e');
          }
        }

        // Update existing messages if their URLs changed (e.g., after file processing)
        final updatedMessages = messagesList.map((newMsg) {
          final existingIndex = _messages.indexWhere((m) => m.id == newMsg.id);
          if (existingIndex != -1) {
            final existingMsg = _messages[existingIndex];
            final existingUrl = existingMsg.voiceUrl ?? existingMsg.attachmentUrl;
            final newUrl = newMsg.voiceUrl ?? newMsg.attachmentUrl;

            // If new message has URL but existing doesn't, update it
            if ((newUrl != null && newUrl.isNotEmpty) &&
                (existingUrl == null || existingUrl.isEmpty)) {
              print('🔄 Updating message ${newMsg.id} with new URL: $newUrl');
              print('   Previous URL: $existingUrl');
              return newMsg;
            }
            // Also update if URLs are different (in case URL changed)
            if ((newUrl != null && newUrl.isNotEmpty) &&
                (existingUrl != null && existingUrl.isNotEmpty) &&
                newUrl != existingUrl) {
              print('🔄 Updating message ${newMsg.id} - URL changed');
              print('   Old URL: $existingUrl');
              print('   New URL: $newUrl');
              return newMsg;
            }
            return existingMsg; // Keep existing if no change
          }
          return newMsg;
        }).toList();

        setState(() {
          _chatDetails = chat;
          _messages.clear();
          _messages.addAll(updatedMessages);
          _isLoading = false;
        });

        // Initialize last message ID and read status tracking for real-time updates
        if (updatedMessages.isNotEmpty) {
          final lastMessageId = updatedMessages.last.id;
          RealtimeUpdateService.initializeChatLastMessage(
            widget.conversation.id,
            lastMessageId,
          );
          RealtimeUpdateService.initializeChatReadStatus(
            widget.conversation.id,
            updatedMessages,
          );
        }

        // Scroll to bottom after loading
        _scrollToBottom();
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
      final response = await CommunicationService.markChatAsRead(chatId: widget.conversation.id);
      if (response.success) {
        print('✅ Chat ${widget.conversation.id} marked as read');
        // Force chat list update to reflect read status
        RealtimeUpdateService.forceUpdate();
      } else {
        print('⚠️ Failed to mark chat as read: ${response.error}');
      }
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
      senderId: _currentUserId, // Use actual current user ID
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
        final realMessageData = response.data as Map<String, dynamic>;
        final realMessage = Message.fromJson(realMessageData);

        // For messages we just sent, ensure senderId is set to current user ID
        // This guarantees the message appears on the right side
        // If _currentUserId is null, try to extract from the real message or use sender.id
        final correctSenderId = _currentUserId ??
                                realMessage.senderId ??
                                realMessage.sender?.id;

        // Update both senderId and ensure sender object also has correct ID
        SenderInfo? updatedSender;
        if (realMessage.sender != null && correctSenderId != null) {
          updatedSender = SenderInfo(
            id: correctSenderId,
            firstName: realMessage.sender!.firstName,
            lastName: realMessage.sender!.lastName,
            fullName: realMessage.sender!.fullName,
            displayName: realMessage.sender!.displayName,
            email: realMessage.sender!.email,
            userType: realMessage.sender!.userType,
            profilePicture: realMessage.sender!.profilePicture,
          );
        }

        final messageWithCorrectSender = realMessage.copyWith(
          senderId: correctSenderId, // Always use current user ID for messages we send
          sender: updatedSender ?? realMessage.sender, // Update sender object if needed
        );

        print('🔍 DEBUG: Message sender ID set to: $correctSenderId (currentUserId: $_currentUserId)');
        print('🔍 DEBUG: Message displaySenderId will be: ${messageWithCorrectSender.displaySenderId}');

        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (index != -1) {
            _messages[index] = messageWithCorrectSender;
          }
        });

        // Update last message ID for real-time updates
        RealtimeUpdateService.initializeChatLastMessage(
          widget.conversation.id,
          messageWithCorrectSender.id,
        );
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

  Future<void> _startVoiceRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission is required to record voice messages'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/voice_$timestamp.m4a';

      // Check if recorder is available
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          path: _recordingPath!,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });

        // Start duration timer
        _startRecordingTimer();

        // Scroll to bottom to show recording indicator
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error starting voice recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
        // Periodically scroll to keep recording indicator visible
        if (_recordingDuration.inSeconds % 3 == 0) {
          _scrollToBottom();
        }
        _startRecordingTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _stopVoiceRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();

        setState(() {
          _isRecording = false;
        });

        if (path != null && path.isNotEmpty) {
          _recordingPath = path;

          // Show dialog to confirm sending or cancel
          if (mounted) {
            final shouldSend = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Voice Recording'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Recording duration: ${_formatDuration(_recordingDuration)}'),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                          child: Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            if (shouldSend == true) {
              // Store duration before resetting state
              final durationInSeconds = _recordingDuration.inSeconds;
              await _sendVoiceMessage(_recordingPath!, durationInSeconds: durationInSeconds);
            } else {
              // Delete the recording file
              try {
                final file = File(_recordingPath!);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (e) {
                print('Error deleting recording: $e');
              }
            }
          }

          // Reset recording state
          setState(() {
            _recordingPath = null;
            _recordingDuration = Duration.zero;
          });
        }
      }
    } catch (e) {
      print('Error stopping voice recording: $e');
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _sendVoiceMessage(String audioPath, {int? durationInSeconds}) async {
    BuildContext? dialogContext;
    try {
      if (!mounted) return;

      // Show loading indicator and store the context
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF8B5CF6),
            ),
          );
        },
      );

      print('🎙️ Sending voice message with duration: ${durationInSeconds ?? "null"} seconds');

      // Send voice message
      final response = await CommunicationService.sendVoiceMessage(
        chatId: widget.conversation.id,
        content: '', // Empty content for voice messages
        attachment: audioPath,
        voiceDuration: durationInSeconds,
      );

      if (mounted) {
        // Close loading dialog using stored context
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }

        if (response.success && response.data != null) {
          // Add the new message directly instead of reloading all messages
          try {
            print('📥 Voice message response: ${response.data}');
            final newMessage = Message.fromJson(response.data as Map<String, dynamic>);
            print('✅ Parsed voice message:');
            print('   ID: ${newMessage.id}');
            print('   Type: ${newMessage.type}');
            print('   voiceUrl: ${newMessage.voiceUrl}');
            print('   attachmentUrl: ${newMessage.attachmentUrl}');
            print('   voiceDuration: ${newMessage.voiceDuration} seconds');
            if (durationInSeconds != null && newMessage.voiceDuration == null) {
              print('⚠️ WARNING: Sent duration ($durationInSeconds) but API returned null duration');
            } else if (durationInSeconds != null && newMessage.voiceDuration != durationInSeconds) {
              print('⚠️ WARNING: Duration mismatch - sent: $durationInSeconds, received: ${newMessage.voiceDuration}');
            }

            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();

            // Reload chat details after a delay to get updated URLs
            // (in case file processing isn't complete yet)
            // Try multiple times with increasing delays
            for (int attempt = 0; attempt < 3; attempt++) {
              final delay = Duration(seconds: 2 + (attempt * 2)); // 2s, 4s, 6s
              Future.delayed(delay, () {
                if (mounted) {
                  print('🔄 Reloading chat details (attempt ${attempt + 1}/3) to get updated voice URLs...');
                  _loadChatDetails();
                }
              });
            }
          } catch (e) {
            print('❌ Error parsing sent message: $e');
            print('❌ Response data: ${response.data}');
            print('❌ Response data type: ${response.data.runtimeType}');
            // Reload chat details as fallback
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                _loadChatDetails();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice sent but failed to display. Refreshing...'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice message sent successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to send voice message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        BuildContext? ctx = dialogContext ?? context;
        if (Navigator.canPop(ctx)) {
          Navigator.pop(ctx);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending voice message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove this chat from real-time monitoring
    RealtimeUpdateService.removeActiveChat(widget.conversation.id);
    _audioRecorder.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleAttachment() {
    // Show bottom sheet with attachment options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Photo option
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImage();
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.image,
                        color: const Color(0xFF8B5CF6),
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Choose from gallery',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    BuildContext? dialogContext;
    try {
      if (!mounted) return;

      // Show dialog to select image source
      final sourceChoice = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: const Color(0xFF8B5CF6)),
                title: Text('Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: const Color(0xFF8B5CF6)),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ],
          ),
        ),
      );

      if (sourceChoice == null) return;

      // Use image_picker to select image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: sourceChoice == 'gallery' ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Show loading indicator and store the context
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            dialogContext = ctx;
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF8B5CF6),
              ),
            );
          },
        );

        try {
          final imageFile = File(image.path);
          if (!await imageFile.exists()) {
            if (mounted) {
              // Close loading dialog using stored context
              if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                Navigator.pop(dialogContext!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Image file not found')),
              );
            }
            return;
          }

          // Send image message with file path
          final response = await CommunicationService.sendImageMessage(
            chatId: widget.conversation.id,
            content: '', // Empty content for image messages
            attachment: image.path,
          );

          if (mounted) {
            // Close loading dialog using stored context
            if (dialogContext != null && Navigator.canPop(dialogContext!)) {
              Navigator.pop(dialogContext!);
            }

            if (response.success && response.data != null) {
              // Add the new message directly instead of reloading all messages
              try {
                print('📥 Image message response: ${response.data}');
                final newMessage = Message.fromJson(response.data as Map<String, dynamic>);
                print('✅ Parsed image message:');
                print('   ID: ${newMessage.id}');
                print('   Type: ${newMessage.type}');
                print('   attachmentUrl: ${newMessage.attachmentUrl}');

                setState(() {
                  _messages.add(newMessage);
                });
                _scrollToBottom();

                // Reload chat details after a short delay to get updated URLs
                // (in case file processing isn't complete yet)
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) {
                    print('🔄 Reloading chat details to get updated image URLs...');
                    _loadChatDetails();
                  }
                });
              } catch (e) {
                print('❌ Error parsing sent message: $e');
                print('❌ Response data: ${response.data}');
                print('❌ Response data type: ${response.data.runtimeType}');
                // Reload chat details as fallback
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    _loadChatDetails();
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Image sent but failed to display. Refreshing...'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image sent successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response.error ?? 'Failed to send image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            // Close loading dialog if still open
            BuildContext? ctx = dialogContext ?? context;
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error sending image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if it was opened
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessagesList()),
            ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
              onVoiceRecord: _startVoiceRecording,
              onVoiceStop: _stopVoiceRecording,
              isRecording: _isRecording,
              onAttachment: _handleAttachment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = _chatDetails?.displayName ?? widget.conversation.displayName;
    final displayAvatar = _chatDetails?.displayAvatar ?? widget.conversation.displayAvatar;
    final isTyping = _isTyping;
    final typingUserName = isTyping ? 'Diva Debew' : null; // TODO: Get actual typing user

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back arrow
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[600], size: 24.sp),
            onPressed: () async {
              // Mark chat as read before going back (if not already done)
              await _markChatAsRead();
              // Force update to refresh chat list
              RealtimeUpdateService.forceUpdate();
              // Small delay to ensure update completes
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/conversations');
              }
            },
          ),

          // Avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: displayAvatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      displayAvatar,
                      width: 40.w,
                      height: 40.w,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar(displayName);
                      },
                    ),
                  )
                : _buildInitialsAvatar(displayName),
          ),

          SizedBox(width: 12.w),

          // Name and typing status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (isTyping && typingUserName != null)
                  Text(
                    '$typingUserName Typing',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),

          // Video and phone icons
          // IconButton(
          //   icon: Icon(Icons.videocam_outlined, color: Colors.grey[600], size: 24.sp),
          //   onPressed: () {
          //     // Handle video call
          //   },
          // ),
          // IconButton(
          //   icon: Icon(Icons.phone_outlined, color: Colors.grey[600], size: 24.sp),
          //   onPressed: () {
          //     // Handle phone call
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                onPressed: _loadChatDetails,
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
      itemCount: _messages.length +
                 (_isTyping ? 1 : 0) +
                 (_isRecording ? 1 : 0),
      itemBuilder: (context, index) {
        // Show recording indicator at the end
        if (_isRecording && index == _messages.length + (_isTyping ? 1 : 0)) {
          return RecordingIndicator(recordingDuration: _recordingDuration);
        }

        // Show typing indicator
        if (_isTyping && index == _messages.length) {
          return const TypingIndicator();
        }

        final message = _messages[index];
        // Determine if message is from current user (sender = right, receiver = left)
        final isMe = message.displaySenderId != null &&
                     _currentUserId != null &&
                     message.displaySenderId == _currentUserId;

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

    if (message.type == MessageType.image) {
      return ImageMessageBubble(
        message: message,
        isMe: isMe,
      );
    }

    return MessageBubble(
      message: message,
      isMe: isMe,
      onDelete: isMe ? () => _deleteMessage(message) : null,
    );
  }

  void _deleteMessage(Message message) {
    // Delete message locally only (no API call)
    setState(() {
      _messages.removeWhere((m) => m.id == message.id);
    });
  }

}
