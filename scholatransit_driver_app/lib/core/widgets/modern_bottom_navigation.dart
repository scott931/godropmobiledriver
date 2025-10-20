import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class ModernBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<ModernBottomNavigation> createState() => _ModernBottomNavigationState();
}

class _ModernBottomNavigationState extends State<ModernBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80.h,
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
        icon: Icons.dashboard_rounded,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
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
        icon: Icons.emergency_rounded,
        activeIcon: Icons.emergency_rounded,
        label: 'Emergency',
        route: '/emergency',
      ),
    ];

    return navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = widget.currentIndex == index;

      return Expanded(
        child: _ModernNavItem(
          item: item,
          isActive: isActive,
          onTap: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            widget.onTap(index);
          },
        ),
      );
    }).toList();
  }
}

class _ModernNavItem extends StatefulWidget {
  final _NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _ModernNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ModernNavItem> createState() => _ModernNavItemState();
}

class _ModernNavItemState extends State<_ModernNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ModernNavItem oldWidget) {
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
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with background
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        widget.isActive
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        size: 24.w,
                        color: widget.isActive
                            ? AppTheme.primaryColor
                            : AppTheme.textTertiary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Label
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
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

// Enhanced version with floating action button integration
class ModernBottomNavigationWithFAB extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onFABTap;
  final IconData? fabIcon;

  const ModernBottomNavigationWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFABTap,
    this.fabIcon,
  });

  @override
  State<ModernBottomNavigationWithFAB> createState() =>
      _ModernBottomNavigationWithFABState();
}

class _ModernBottomNavigationWithFABState
    extends State<ModernBottomNavigationWithFAB>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
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
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildNavigationItems(),
              ),
            ),
          ),
        ),
        // Floating Action Button
        if (widget.onFABTap != null)
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
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.r),
                          onTap: widget.onFABTap,
                          child: Icon(
                            widget.fabIcon ?? Icons.add_rounded,
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
        icon: Icons.dashboard_rounded,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
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
        icon: Icons.emergency_rounded,
        activeIcon: Icons.emergency_rounded,
        label: 'Emergency',
        route: '/emergency',
      ),
    ];

    return navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isActive = widget.currentIndex == index;

      return Expanded(
        child: _ModernNavItem(
          item: item,
          isActive: isActive,
          onTap: () => widget.onTap(index),
        ),
      );
    }).toList();
  }
}
