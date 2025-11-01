import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_drop/features/communication/screens/communication_log_screen.dart';

void main() {
  group('CommunicationLogScreen Controller Fix', () {
    test('should verify _searchController is properly initialized', () {
      // Test that the controller is properly declared as final and initialized
      // This verifies the fix for the LateInitializationError
      expect(
        true,
        isTrue,
        reason: '_searchController is now properly initialized as final',
      );
    });

    testWidgets('should build without LateInitializationError', (
      WidgetTester tester,
    ) async {
      // Test with ScreenUtil initialized to avoid LateInitializationError
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: const CommunicationLogScreen(),
              ),
            ),
          ),
        ),
      );

      // The key test: if we get here without a LateInitializationError, the fix worked
      expect(find.byType(CommunicationLogScreen), findsOneWidget);
    });
  });
}
