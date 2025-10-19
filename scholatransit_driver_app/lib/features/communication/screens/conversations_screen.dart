import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/models/conversation_model.dart';
import 'whatsapp_redirect_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isCreating = false;
  bool _isLoading = false;
  String? _error;
  final List<Conversation> _conversations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.listChats();
      if (response.success && response.data != null) {
        final chatsData = response.data!;
        final chatsList =
            (chatsData['results'] as List?)
                ?.map((chat) => Conversation.fromJson(chat))
                .toList() ??
            [];

        setState(() {
          _conversations.clear();
          _conversations.addAll(chatsList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchChats() async {
    if (_searchController.text.trim().isEmpty) {
      _loadConversations();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.searchChats(
        query: _searchController.text.trim(),
      );
      if (response.success && response.data != null) {
        final chatsData = response.data!;
        final chatsList =
            (chatsData['results'] as List?)
                ?.map((chat) => Conversation.fromJson(chat))
                .toList() ??
            [];

        setState(() {
          _conversations.clear();
          _conversations.addAll(chatsList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to search conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to search conversations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await CommunicationService.getUnreadCount();
      if (response.success && response.data != null) {
        // Update unread count in conversations if needed
        // This could be used to show a badge on the conversations tab
        print('Unread count: ${response.data}');
      }
    } catch (e) {
      // Silently handle unread count errors
      print('Failed to load unread count: $e');
    }
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 8,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 400.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, const Color(0xFFF8FAFC)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 32.w,
                    color: const Color(0xFF0052CC),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  'Start New Conversation',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  'Choose who you want to chat with',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Chat Options
                _buildChatOption(
                  icon: Icons.family_restroom,
                  title: 'Chat with Parent',
                  subtitle: 'Connect with student\'s parent',
                  onTap: () {
                    Navigator.of(context).pop();
                    _createChatWithParent();
                  },
                  color: const Color(0xFF059669),
                ),
                SizedBox(height: 12.h),

                _buildChatOption(
                  icon: Icons.admin_panel_settings,
                  title: 'Chat with Admin',
                  subtitle: 'Contact school administration',
                  onTap: () {
                    Navigator.of(context).pop();
                    _createChatWithAdmin();
                  },
                  color: const Color(0xFF0052CC),
                ),
                SizedBox(height: 24.h),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, size: 20.w, color: color),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createChatWithParent() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    // Create a driver-parent chat for student ID 1
    final res = await CommunicationService.createDriverParentChat(studentId: 1);

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver-Parent chat created')),
      );
      // Refresh the conversations list
      _loadConversations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to create chat')),
      );
    }
  }

  Future<void> _createChatWithAdmin() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    // Create an admin-driver chat for driver ID 8 (current user)
    final res = await CommunicationService.createAdminDriverChat(driverId: 8);

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin-Driver chat created')),
      );
      // Refresh the conversations list
      _loadConversations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to create chat')),
      );
    }
  }

  void _navigateToChat(Conversation conversation) {
    // Redirect to WhatsApp instead of the built-in chat
    context.go(
      '/conversations/whatsapp-redirect',
      extra: {
        'contactName': conversation.studentName,
        'contactType': 'parent',
        'phoneNumber': conversation
            .parentPhone, // You'll need to add this to your Conversation model
      },
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
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showCreateChatDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                onPressed: _loadConversations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No conversations yet',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton.icon(
                onPressed: _isCreating ? null : _showCreateChatDialog,
                icon: _isCreating
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: Text(_isCreating ? 'Creating…' : 'Create Conversation'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Conversations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            Navigator.pop(context);
            _searchChats();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              _loadConversations();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchChats();
            },
            child: const Text('Search'),
          ),
        ],
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
