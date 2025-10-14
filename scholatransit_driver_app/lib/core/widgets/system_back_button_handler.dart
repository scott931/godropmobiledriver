import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SystemBackButtonHandler extends StatefulWidget {
  final Widget child;

  const SystemBackButtonHandler({super.key, required this.child});

  @override
  State<SystemBackButtonHandler> createState() =>
      _SystemBackButtonHandlerState();
}

class _SystemBackButtonHandlerState extends State<SystemBackButtonHandler> {
  @override
  void initState() {
    super.initState();
    // Set up system back button handling
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Always prevent default back behavior
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleSystemBackButton();
        }
      },
      child: widget.child,
    );
  }

  void _handleSystemBackButton() {
    final router = GoRouter.of(context);

    // Check if we can pop the current route
    if (router.canPop()) {
      router.pop();
    } else {
      // We're at the root - show exit confirmation
      _showExitConfirmation();
    }
  }

  void _showExitConfirmation() {
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
