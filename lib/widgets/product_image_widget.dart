import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({super.key, this.imageUrl, this.width = 48, this.height = 48});

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return _fallback();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : SizedBox(width: width, height: height, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
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
