import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> showBarcodeScanner(BuildContext context) => Navigator.of(
  context,
).push<String>(
  MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen()),
);

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool handled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Scan Product Barcode'),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (handled) return;
            final codes = capture.barcodes
                .map((barcode) => barcode.rawValue?.trim())
                .whereType<String>()
                .where((value) => value.isNotEmpty);
            if (codes.isEmpty) return;
            handled = true;
            Navigator.of(context).pop(codes.first);
          },
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text(
            'Place the product barcode inside the frame. It will be captured automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );
}
