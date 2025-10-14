import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CleanBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CleanBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CleanBottomNavigation> createState() => _CleanBottomNavigationState();
}

class _CleanBottomNavigationState extends State<CleanBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavigationItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    final navigationItems = [
      _NavigationItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/dashboard',
      ),
      _NavigationItem(
        icon: Icons.directions_bus_rounded,
        activeIcon: Icons.directions_bus_rounded,
        label: 'Trips',
        route: '/trips',
      ),
      _NavigationItem(
        icon: Icons.school_rounded,
        activeIcon: Icons.school_rounded,
        label: 'Students',
        route: '/students',
      ),
      _NavigationItem(
        icon: Icons.map_rounded,
        activeIcon: Icons.map_rounded,
        label: 'Map',
        route: '/map',
      ),
      _NavigationItem(
        icon: Icons.notifications_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts',
        route: '/notifications',
      ),
    ];

    return navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = widget.currentIndex == index;

      return Expanded(
        child: _CleanNavItem(
          item: item,
          isActive: isActive,
          onTap: () => widget.onTap(index),
        ),
      );
    }).toList();
  }
}

class _CleanNavItem extends StatefulWidget {
  final _NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _CleanNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CleanNavItem> createState() => _CleanNavItemState();
}

class _CleanNavItemState extends State<_CleanNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CleanNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean icon
                  Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    size: 24.w,
                    color: widget.isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiary,
                  ),
                  SizedBox(height: 4.h),
                  // Clean label
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive
                          ? AppTheme.primaryColor
                          : AppTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// Alternative version with floating action button
class CleanBottomNavigationWithFAB extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CleanBottomNavigationWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CleanBottomNavigationWithFAB> createState() =>
      _CleanBottomNavigationWithFABState();
}

class _CleanBottomNavigationWithFABState
    extends State<CleanBottomNavigationWithFAB>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main navigation bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildNavigationItems(),
              ),
            ),
          ),
        ),
        // Floating Action Button
        Positioned(
          top: -20.h,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28.r),
                        onTap: () => context.go('/emergency/create-alert'),
                        child: Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavigationItems() {
    final navigationItems = [
      _NavigationItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/dashboard',
      ),
      _NavigationItem(
        icon: Icons.directions_bus_rounded,
        activeIcon: Icons.directions_bus_rounded,
        label: 'Trips',
        route: '/trips',
      ),
      _NavigationItem(
        icon: Icons.school_rounded,
        activeIcon: Icons.school_rounded,
        label: 'Students',
        route: '/students',
      ),
      _NavigationItem(
        icon: Icons.map_rounded,
        activeIcon: Icons.map_rounded,
        label: 'Map',
        route: '/map',
      ),
      _NavigationItem(
        icon: Icons.notifications_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts',
        route: '/notifications',
      ),
    ];

    return navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = widget.currentIndex == index;

      return Expanded(
        child: _CleanNavItem(
          item: item,
          isActive: isActive,
          onTap: () => widget.onTap(index),
        ),
      );
    }).toList();
  }
}
