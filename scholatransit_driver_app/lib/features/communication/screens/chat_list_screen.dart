import 'package:flutter/material.dart';
import '../../../core/utils/avatar_color_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/services/realtime_update_service.dart';
import '../../../core/services/storage_service.dart';

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

  // Light blue color for icons (matching the design)
  final Color _lightBlueColor = const Color(0xFF4A90E2);

  bool _hasInitialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Start real-time updates after a small delay to avoid interfering with initial load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startRealtimeUpdates();
      }
    });
  }

  // Track if we've already initialized to avoid duplicate refreshes
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh once when screen becomes visible (to avoid too many calls)
    if (!_hasInitialized) {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null && modalRoute.isCurrent) {
        _hasInitialized = true;
        // Screen is now current, silently refresh chats (no loading indicator)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasInitialLoadCompleted) {
            // Only do silent refresh if initial load is done
            _loadChatsSilently();
          }
        });
      }
    }
  }

  void _startRealtimeUpdates() {
    // Start real-time polling for chat list updates (silent background refresh)
    RealtimeUpdateService.startPolling(
      onChatListUpdated: (updatedChats) {
        // Update chat list with new data silently in background (no loading indicator)
        // Only update if initial load has completed
        if (mounted && _hasInitialLoadCompleted) {
          setState(() {
            _chats = updatedChats;
            // Don't modify _isLoading or _error here - keep existing state
            // This ensures background updates don't show loading indicators or UI changes
          });
        }
      },
      onUnreadCountUpdated: (unreadCount) {
        // Silently refresh chat list in background without showing loading
        // Only update if initial load has completed
        if (mounted && _hasInitialLoadCompleted) {
          _loadChatsSilently();
        }
      },
    );
  }

  @override
  void dispose() {
    // Note: We don't stop polling here because other screens might need it
    // The service handles cleanup internally
    super.dispose();
  }

  Future<void> _loadChats() async {
    // Only show loading indicator if this is the initial load
    if (!_hasInitialLoadCompleted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
            .whereType<Map<String, dynamic>>()
            .map(
              (chatJson) =>
                  Conversation.fromJson(chatJson as Map<String, dynamic>),
            )
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
          _hasInitialLoadCompleted = true;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load chats';
          _isLoading = false;
          _hasInitialLoadCompleted = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load chats: $e';
        _isLoading = false;
        _hasInitialLoadCompleted = true;
      });
    }
  }

  /// Load chats silently in background without showing loading indicator
  Future<void> _loadChatsSilently() async {
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
            .whereType<Map<String, dynamic>>()
            .map(
              (chatJson) =>
                  Conversation.fromJson(chatJson as Map<String, dynamic>),
            )
            .toList();

        // Sort chats: pinned first, then by last message time
        chatsList.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.id.compareTo(a.id); // Fallback: newest first
        });

        // Update silently without modifying loading or error states
        if (mounted) {
          setState(() {
            _chats = chatsList;
            // Don't modify _isLoading or _error - keep existing state
          });
        }
      }
      // Silently ignore errors in background refresh
    } catch (e) {
      // Silently ignore errors in background refresh
      print('⚠️ ChatListScreen: Silent refresh error (ignored): $e');
    }
  }

  Future<void> _refreshChats() async {
    // Manual refresh - show loading indicator
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Reset the flag temporarily to allow loading indicator
    final wasCompleted = _hasInitialLoadCompleted;
    _hasInitialLoadCompleted = false;
    await _loadChats();
    // Restore the flag
    _hasInitialLoadCompleted = wasCompleted;
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
            .whereType<Map<String, dynamic>>()
            .map(
              (chatJson) =>
                  Conversation.fromJson(chatJson as Map<String, dynamic>),
            )
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

  List<Conversation> get _pinnedChats {
    return _filteredChats.where((chat) => chat.isPinned).toList();
  }

  List<Conversation> get _allChats {
    return _filteredChats.where((chat) => !chat.isPinned).toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Chat List
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Chat Title
          Text(
            'Chat',
            style: GoogleFonts.poppins(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          // Action Icons
          // Row(
          //   children: [
          //     // Camera Icon
          //     _buildIconButton(
          //       icon: Icons.camera_alt_outlined,
          //       onTap: () {
          //         // TODO: Implement camera functionality
          //       },
          //     ),
          //     SizedBox(width: 12.w),
          //     // Pencil/Edit Icon
          //     _buildIconButton(
          //       icon: Icons.edit_outlined,
          //       onTap: () {
          //         // TODO: Implement edit functionality
          //       },
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _lightBlueColor, size: 22.sp),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            if (value.isNotEmpty) {
              _searchChats(value);
            } else {
              // If search is cleared, silently refresh if initial load is done
              if (_hasInitialLoadCompleted) {
                _loadChatsSilently();
              } else {
                _loadChats();
              }
            }
          },
          decoration: InputDecoration(
            hintText: 'Search chat...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15.sp,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[400],
              size: 20.sp,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[400],
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      // If search is cleared, silently refresh if initial load is done
                      if (_hasInitialLoadCompleted) {
                        _loadChatsSilently();
                      } else {
                        _loadChats();
                      }
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    // Ensure real-time updates are running - verify callbacks are set (silent check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Re-register callbacks if they were lost (defensive programming)
        if (RealtimeUpdateService.onChatListUpdated == null) {
          _startRealtimeUpdates();
        }
      }
    });

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
              ElevatedButton(onPressed: _loadChats, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final pinnedChats = _pinnedChats;
    final allChats = _allChats;

    if (pinnedChats.isEmpty && allChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isNotEmpty ? 'No chats found' : 'No chats yet',
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
        padding: EdgeInsets.only(bottom: 8.h),
        itemCount:
            (pinnedChats.isNotEmpty ? 1 : 0) +
            pinnedChats.length +
            (allChats.isNotEmpty ? 1 : 0) +
            allChats.length,
        itemBuilder: (context, index) {
          // PINNED MESSAGE section header
          if (pinnedChats.isNotEmpty && index == 0) {
            return _buildSectionHeader('PINNED MESSAGE');
          }

          // Pinned chats
          if (pinnedChats.isNotEmpty &&
              index > 0 &&
              index <= pinnedChats.length) {
            return _buildChatItem(pinnedChats[index - 1]);
          }

          // ALL MESSAGE section header
          if (pinnedChats.isNotEmpty) {
            final allMessageIndex = pinnedChats.length + 1;
            if (index == allMessageIndex) {
              return _buildSectionHeader('ALL MESSAGE');
            }
            if (index > allMessageIndex) {
              return _buildChatItem(allChats[index - allMessageIndex - 1]);
            }
          } else {
            // No pinned chats, so ALL MESSAGE header is at index 0
            if (index == 0) {
              return _buildSectionHeader('ALL MESSAGE');
            }
            return _buildChatItem(allChats[index - 1]);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChatItem(Conversation chat) {
    final displayName = chat.student != null && chat.chatType == 'driver_parent'
        ? chat.student!.fullName
        : chat.otherParticipant.name;

    final displayAvatar =
        chat.studentAvatar ?? chat.otherParticipant.profilePicture;
    final hasUnread = chat.unreadCount > 0;

    // Get current user ID to check if last message is from current user
    final currentUserId = StorageService.getUserProfile()?['id'] as int?;
    final lastMessage = chat.lastMessage;
    final isLastMessageFromMe =
        lastMessage != null &&
        currentUserId != null &&
        lastMessage.displaySenderId == currentUserId;
    final isLastMessageRead = lastMessage?.isRead ?? false;

    return InkWell(
      onTap: () async {
        // Navigate to chat
        await context.push(
          '/conversations/chat/${chat.id}',
          extra: {'conversation': chat},
        );
        // When returning from chat, silently refresh the list to update unread count
        if (mounted && _hasInitialLoadCompleted) {
          _loadChatsSilently();
        } else if (mounted) {
          _loadChats();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: Colors.white,
        child: Row(
          children: [
            // Profile Picture/Initials
            _buildAvatar(displayAvatar, displayName),

            SizedBox(width: 12.w),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Name
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Timestamp
                      Text(
                        chat.lastMessageTime ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      // Last Message Preview
                      Expanded(
                        child: Text(
                          chat.latestMessagePreview ?? 'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Status Indicator
                      if (hasUnread)
                        _buildUnreadBadge(chat.unreadCount)
                      else if (isLastMessageFromMe)
                        // Show one tick for sent, two ticks for read
                        isLastMessageRead
                            ? _buildReadIndicator()
                            : _buildSentIndicator()
                      else
                        // No indicator for messages from others
                        const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarUrl == null ? Colors.grey[300] : Colors.transparent,
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 56.w,
                height: 56.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(name);
                },
              ),
            )
          : _buildInitialsAvatar(name),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    final backgroundColor = AvatarColorUtils.getColorForName(name);
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
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

  Widget _buildReadIndicator() {
    // Show two ticks for read messages
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all, size: 16.sp, color: _lightBlueColor),
        SizedBox(width: 2.w),
        Icon(Icons.done_all, size: 16.sp, color: _lightBlueColor),
      ],
    );
  }

  Widget _buildSentIndicator() {
    // Show one tick for sent messages (not yet read)
    return Icon(Icons.done, size: 16.sp, color: _lightBlueColor);
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(color: _lightBlueColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
