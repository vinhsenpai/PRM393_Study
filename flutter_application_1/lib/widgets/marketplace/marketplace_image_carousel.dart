import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';

class MarketplaceImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  const MarketplaceImageCarousel({super.key, required this.imageUrls, this.height = 280});

  @override
  State<MarketplaceImageCarousel> createState() => _MarketplaceImageCarouselState();
}

class _MarketplaceImageCarouselState extends State<MarketplaceImageCarousel> {
  late final PageController _controller;
  int _index = 0;

  List<String> get _images => widget.imageUrls.where((e) => e.trim().isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    if (images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 56, color: Color(0xFF6B6B6B)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    if (!mounted) return;
                    setState(() => _index = i.clamp(0, images.length - 1));
                  },
                  itemBuilder: (context, i) {
                    final url = images[i];
                    return CachedNetworkImage(

                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, _, __) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 44, color: Color(0xFF6B6B6B)),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.12)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

