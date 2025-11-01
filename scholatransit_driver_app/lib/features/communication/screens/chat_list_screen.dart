import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/services/communication_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _chats = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadUnreadCount();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.listChats();

      if (response.success && response.data != null) {
        // Handle both direct list response and wrapped response
        List<dynamic> chatsData;
        if (response.data is List) {
          chatsData = response.data as List;
        } else if (response.data is Map<String, dynamic>) {
          // Check common wrapping keys
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('results')) {
            chatsData = data['results'] as List? ?? [];
          } else if (data.containsKey('data')) {
            chatsData = data['data'] as List? ?? [];
          } else {
            // If it's a single object, wrap it in a list
            chatsData = [data];
          }
        } else {
          chatsData = [];
        }

        final chatsList = chatsData
            .where((chatJson) => chatJson is Map<String, dynamic>)
            .map((chatJson) => Conversation.fromJson(chatJson as Map<String, dynamic>))
            .toList();

        // Sort chats: pinned first, then by last message time
        chatsList.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // TODO: Sort by last_message_time if available
          return b.id.compareTo(a.id); // Fallback: newest first
        });

        setState(() {
          _chats = chatsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await CommunicationService.getUnreadCount();
      if (response.success && response.data != null) {
        setState(() {
          _unreadCount = response.data!['unread_count'] as int? ?? 0;
        });
      }
    } catch (e) {
      // Silently handle error
      print('Failed to load unread count: $e');
    }
  }

  Future<void> _refreshChats() async {
    await Future.wait([
      _loadChats(),
      _loadUnreadCount(),
    ]);
  }

  Future<void> _searchChats(String query) async {
    if (query.isEmpty) {
      _loadChats();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await CommunicationService.searchChats(query: query);

      if (response.success && response.data != null) {
        // Handle both direct list response and wrapped response
        List<dynamic> chatsData;
        if (response.data is List) {
          chatsData = response.data as List;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('results')) {
            chatsData = data['results'] as List? ?? [];
          } else if (data.containsKey('data')) {
            chatsData = data['data'] as List? ?? [];
          } else {
            chatsData = [];
          }
        } else {
          chatsData = [];
        }

        final chatsList = chatsData
            .where((chatJson) => chatJson is Map<String, dynamic>)
            .map((chatJson) => Conversation.fromJson(chatJson as Map<String, dynamic>))
            .toList();

        setState(() {
          _chats = chatsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to search chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to search chats: $e';
        _isLoading = false;
      });
    }
  }


  List<Conversation> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    return _chats.where((chat) {
      final participantName = chat.otherParticipant.name.toLowerCase();
      final studentName = chat.student?.fullName.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return participantName.contains(query) || studentName.contains(query);
    }).toList();
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
          'Chats',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isNotEmpty) {
                  _searchChats(value);
                } else {
                  _loadChats();
                }
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadChats();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
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
                onPressed: _loadChats,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredChats = _filteredChats;

    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No chats found'
                  : 'No chats yet',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView.builder(
        itemCount: filteredChats.length,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          return _buildChatItem(chat);
        },
      ),
    );
  }

  Widget _buildChatItem(Conversation chat) {
    final displayName = chat.student != null && chat.chatType == 'driver_parent'
        ? chat.student!.fullName
        : chat.otherParticipant.name;

    final displayAvatar = chat.studentAvatar ?? chat.otherParticipant.profilePicture;
    final isOnline = chat.otherParticipant.isOnline;

    return InkWell(
      onTap: () {
        context.push(
          '/conversations/chat/${chat.id}',
          extra: {'conversation': chat},
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: chat.isPinned ? Colors.grey[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
            left: chat.isPinned
                ? BorderSide(color: const Color(0xFF10B981), width: 4.w)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundImage: displayAvatar != null
                      ? NetworkImage(displayAvatar)
                      : null,
                  child: displayAvatar == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.sp,
                          ),
                        )
                      : null,
                  backgroundColor: const Color(0xFF10B981),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isPinned)
                        Icon(
                          Icons.push_pin,
                          size: 16.w,
                          color: Colors.grey[600],
                        ),
                      SizedBox(width: 8.w),
                      Text(
                        chat.lastMessageTime ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.latestMessagePreview ?? 'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (chat.student != null && chat.chatType == 'driver_parent')
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        'Parent: ${chat.otherParticipant.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

