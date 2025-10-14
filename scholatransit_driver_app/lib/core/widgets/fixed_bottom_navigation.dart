import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class FixedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FixedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FixedBottomNavigation> createState() => _FixedBottomNavigationState();
}

class _FixedBottomNavigationState extends State<FixedBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65.h,
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
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/dashboard',
      ),
      _NavItem(
        icon: Icons.directions_bus_outlined,
        activeIcon: Icons.directions_bus_rounded,
        label: 'Trips',
        route: '/trips',
      ),
      _NavItem(
        icon: Icons.school_outlined,
        activeIcon: Icons.school_rounded,
        label: 'Students',
        route: '/students',
      ),
      _NavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Map',
        route: '/map',
      ),
      _NavItem(
        icon: Icons.notifications_outlined,
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
        child: _FixedNavItem(
          item: item,
          isActive: isActive,
          onTap: () => widget.onTap(index),
        ),
      );
    }).toList();
  }
}

class _FixedNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _FixedNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FixedNavItem> createState() => _FixedNavItemState();
}

class _FixedNavItemState extends State<_FixedNavItem>
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
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FixedNavItem oldWidget) {
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
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Simple icon
                  Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    size: 22.w,
                    color: widget.isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiary,
                  ),
                  SizedBox(height: 4.h),
                  // Simple label
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 9.sp,
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// Version with floating action button
class FixedBottomNavigationWithFAB extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FixedBottomNavigationWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FixedBottomNavigationWithFAB> createState() =>
      _FixedBottomNavigationWithFABState();
}

class _FixedBottomNavigationWithFABState
    extends State<FixedBottomNavigationWithFAB>
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
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65.h,
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
          top: -18.h,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26.r),
                        onTap: () => context.go('/emergency/create-alert'),
                        child: Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 22.w,
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
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/dashboard',
      ),
      _NavItem(
        icon: Icons.directions_bus_outlined,
        activeIcon: Icons.directions_bus_rounded,
        label: 'Trips',
        route: '/trips',
      ),
      _NavItem(
        icon: Icons.school_outlined,
        activeIcon: Icons.school_rounded,
        label: 'Students',
        route: '/students',
      ),
      _NavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Map',
        route: '/map',
      ),
      _NavItem(
        icon: Icons.notifications_outlined,
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
        child: _FixedNavItem(
          item: item,
          isActive: isActive,
          onTap: () => widget.onTap(index),
        ),
      );
    }).toList();
  }
}
