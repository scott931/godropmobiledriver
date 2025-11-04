import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../services/realtime_update_service.dart';
import '../services/communication_service.dart';

class SimpleBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SimpleBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<SimpleBottomNavigation> createState() => _SimpleBottomNavigationState();
}

class _SimpleBottomNavigationState extends State<SimpleBottomNavigation> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startListeningToUpdates();
  }

  void _loadUnreadCount() async {
    try {
      final response = await CommunicationService.getUnreadCount();
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final count = data['unread_count'] as int? ?? 0;
        print('📊 BottomNav: Loaded unread count: $count');
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      } else {
        print('⚠️ BottomNav: Failed to load unread count: ${response.error}');
        // Try to calculate from chat list as fallback
        _calculateUnreadFromChatList();
      }
    } catch (e) {
      print('❌ BottomNav: Error loading unread count: $e');
      // Try to calculate from chat list as fallback
      _calculateUnreadFromChatList();
    }
  }

  void _calculateUnreadFromChatList() async {
    try {
      final response = await CommunicationService.listChats();
      if (response.success && response.data != null) {
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

        int totalUnread = 0;
        for (var chatJson in chatsData) {
          if (chatJson is Map<String, dynamic>) {
            final unreadCount = chatJson['unread_count'] as int? ?? 0;
            totalUnread += unreadCount;
          }
        }

        print('📊 BottomNav: Calculated unread count from chat list: $totalUnread');
        if (mounted) {
          setState(() {
            _unreadCount = totalUnread;
          });
        }
      }
    } catch (e) {
      print('❌ BottomNav: Error calculating unread from chat list: $e');
    }
  }

  void _startListeningToUpdates() {
    // Listen to real-time unread count updates
    RealtimeUpdateService.startPolling(
      onUnreadCountUpdated: (unreadCount) {
        print('📊 BottomNav: Unread count updated: $unreadCount');
        if (mounted) {
          setState(() {
            _unreadCount = unreadCount;
          });
        }
      },
      onChatListUpdated: (updatedChats) {
        // Calculate unread count from chat list as backup
        int totalUnread = 0;
        for (var chat in updatedChats) {
          totalUnread += chat.unreadCount;
        }
        print('📊 BottomNav: Calculated unread from chat list update: $totalUnread');
        if (mounted) {
          setState(() {
            _unreadCount = totalUnread;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Log current unread count
    print('🔴 BottomNav: Building with unread count: $_unreadCount, should show badge: ${_unreadCount > 0}');

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.directions_bus_outlined,
                activeIcon: Icons.directions_bus_rounded,
                label: 'Trips',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
                label: 'Students',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Map',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Conversations',
                index: 4,
                showBadge: _unreadCount > 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    bool showBadge = false,
  }) {
    final isActive = widget.currentIndex == index;

    // Debug: Log badge state for conversation icon
    if (index == 4) {
      print('🔴 BottomNav: Conversation icon - showBadge: $showBadge');
    }

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with badge wrapper
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 20.w,
                      color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary,
                    ),
                  ),
                  // Red badge indicator for unread messages
                  if (showBadge && index == 4)
                    Positioned(
                      right: -2.w,
                      top: -2.h,
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.9),
                              blurRadius: 3,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
