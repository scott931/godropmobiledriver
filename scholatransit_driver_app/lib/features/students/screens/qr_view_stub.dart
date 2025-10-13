// Fallback stub for non-supported platforms
import 'package:flutter/widgets.dart';

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = const Color(0xFF000000),
    this.borderRadius = 0,
    this.borderLength = 0,
    this.borderWidth = 0,
    this.cutOutSize = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class QRViewController {
  Stream<Barcode> get scannedDataStream => const Stream.empty();
  Future<void> toggleFlash() async {}
  Future<void> flipCamera() async {}
  void dispose() {}
}

class Barcode {
  final String? code;
  const Barcode(this.code);
}

class QRView extends StatelessWidget {
  final Key? key;
  final void Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape? overlay;

  const QRView({this.key, required this.onQRViewCreated, this.overlay});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

