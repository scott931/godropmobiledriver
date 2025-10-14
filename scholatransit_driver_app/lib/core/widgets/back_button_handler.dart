import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BackButtonHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBackPressed;
  final bool canPop;

  const BackButtonHandler({
    super.key,
    required this.child,
    this.onBackPressed,
    this.canPop = true,
  });

  @override
  State<BackButtonHandler> createState() => _BackButtonHandlerState();
}

class _BackButtonHandlerState extends State<BackButtonHandler> {
  @override
  void initState() {
    super.initState();
    // Set up system back button handling
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackButton(context);
        }
      },
      child: widget.child,
    );
  }

  void _handleBackButton(BuildContext context) {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else {
      // Default back button behavior
      if (context.canPop()) {
        context.pop();
      } else {
        // If we can't pop, we're at the root - show exit confirmation
        _showExitConfirmation(context);
      }
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
