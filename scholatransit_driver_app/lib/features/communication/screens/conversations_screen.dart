import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/models/conversation_model.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isCreating = false;
  final List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    // Sample conversations
    setState(() {
      _conversations.addAll([
        Conversation(
          id: 1,
          title: 'Jeff Johnson',
          description: 'Parent communication',
          conversationType: 'parent_driver',
          studentId: 1,
          studentName: 'Jeff Johnson',
          studentAvatar: null,
          vehicleId: 1,
          routeId: 1,
          isModerated: false,
          participantIds: [1, 2],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isOnline: true,
          unreadCount: 2,
        ),
        Conversation(
          id: 2,
          title: 'Sarah Wilson',
          description: 'Student pickup coordination',
          conversationType: 'parent_driver',
          studentId: 2,
          studentName: 'Sarah Wilson',
          studentAvatar: null,
          vehicleId: 1,
          routeId: 1,
          isModerated: false,
          participantIds: [1, 3],
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          isOnline: false,
          unreadCount: 0,
        ),
      ]);
    });
  }

  Future<void> _createSampleConversation() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    final res = await CommunicationService.createConversation(
      conversationType: 'parent_driver',
      student: 1,
      vehicle: 1,
      route: 1,
      title: 'Test Chat',
      description: 'Communication between parent and driver',
      isModerated: false,
      moderator: null,
      // participantIds: [1], // optional RAW variant
    );
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (res.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation created')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to create conversation')),
      );
    }
  }

  void _navigateToChat(Conversation conversation) {
    context.go(
      '/conversations/chat/${conversation.id}',
      extra: {'conversation': conversation},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Conversations',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _createSampleConversation,
          ),
        ],
      ),
      body: _conversations.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start a new conversation',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createSampleConversation,
                      icon: _isCreating
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        _isCreating ? 'Creating…' : 'Create Conversation',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationTile(conversation);
              },
            ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return ListTile(
      onTap: () => _navigateToChat(conversation),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundImage: conversation.studentAvatar != null
                ? NetworkImage(conversation.studentAvatar!)
                : null,
            child: conversation.studentAvatar == null
                ? Text(
                    conversation.studentName.isNotEmpty
                        ? conversation.studentName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          if (conversation.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversation.studentName,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage?.content ?? 'No messages yet',
        style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.updatedAt),
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
          if (conversation.unreadCount > 0) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
