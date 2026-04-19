import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedPostImage extends StatelessWidget {
  const CachedPostImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      maxHeightDiskCache: 1200,
      memCacheHeight: 600,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}
