import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.contain,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return _fallback();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    color: const Color(0xFFF3F4F6),
    child: const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
  );
}

class ProductStickerImageWidget extends StatelessWidget {
  const ProductStickerImageWidget({
    super.key,
    required this.product,
    this.imageUrl,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.contain,
  });

  final Map<String, dynamic> product;
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  Map<String, dynamic> get _details {
    final raw = product['manual_details'];
    return raw is Map ? raw.cast<String, dynamic>() : const {};
  }

  String get _barcode {
    final saved = product['barcode']?.toString().trim() ?? '';
    return saved.isNotEmpty ? saved : product['sku']?.toString().trim() ?? '';
  }

  double _number(String key, double fallback) =>
      double.tryParse('${_details[key] ?? ''}') ?? fallback;

  @override
  Widget build(BuildContext context) {
    final details = _details;
    final showSticker =
        _barcode.isNotEmpty &&
        details['sticker_placement']?.toString().isNotEmpty == true;
    final productDegrees = _number('product_preview_rotation_degrees', 0);
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _number('sticker_scale', 1).clamp(.5, 1.5);
          final stickerDegrees = _number('sticker_rotation_degrees', 0).round();
          final turns = ((stickerDegrees ~/ 90) % 4 + 4) % 4;
          final stickerWidth = constraints.maxWidth * .44 * scale;
          final stickerHeight = constraints.maxHeight * .23 * scale;
          final rotated = turns.isOdd;
          final displayWidth = rotated ? stickerHeight : stickerWidth;
          final displayHeight = rotated ? stickerWidth : stickerHeight;
          final maxLeft = math.max(0.0, constraints.maxWidth - displayWidth);
          final maxTop = math.max(0.0, constraints.maxHeight - displayHeight);
          final x = _number('sticker_position_x', 1).clamp(0.0, 1.0);
          final y = _number('sticker_position_y', 1).clamp(0.0, 1.0);
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.rotate(
                  angle: productDegrees * math.pi / 180,
                  child: ProductImageWidget(
                    imageUrl: imageUrl,
                    width: width,
                    height: height,
                    fit: fit,
                  ),
                ),
                if (showSticker)
                  Positioned(
                    left: x * maxLeft,
                    top: y * maxTop,
                    child: RotatedBox(
                      quarterTurns: turns,
                      child: Container(
                        key: ValueKey(
                          'saved-product-sticker-${product['product_id'] ?? product['id'] ?? _barcode}',
                        ),
                        width: stickerWidth,
                        height: stickerHeight,
                        padding: EdgeInsets.all(
                          math.max(1, constraints.maxWidth * .012),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF102A43),
                            width: math.max(.6, constraints.maxWidth * .009),
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _SavedBarcodePainter(_barcode),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SavedBarcodePainter extends CustomPainter {
  const _SavedBarcodePainter(this.barcode);

  final String barcode;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..color = const Color(0xFF111111);
    final digits = barcode.codeUnits.isEmpty ? [1] : barcode.codeUnits;
    final modules = math.max(18, digits.length * 3);
    final moduleWidth = size.width / modules;
    var cursor = 0;
    var index = 0;
    while (cursor < modules) {
      final digit = digits[index % digits.length];
      final barModules = 1 + digit % 2;
      final gapModules = 1 + (digit ~/ 2) % 2;
      canvas.drawRect(
        Rect.fromLTWH(
          cursor * moduleWidth,
          0,
          math.min(barModules * moduleWidth, size.width - cursor * moduleWidth),
          size.height,
        ),
        paint,
      );
      cursor += barModules + gapModules;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _SavedBarcodePainter oldDelegate) =>
      oldDelegate.barcode != barcode;
}
