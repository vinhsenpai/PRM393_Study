// Marketplace shared UI widgets (reusable)

import 'package:flutter/material.dart';

class MarketplaceChipRow extends StatelessWidget {
  final List<String> chips;
  final int maxChips;
  final double spacing;
  const MarketplaceChipRow({super.key, required this.chips, this.maxChips = 6, this.spacing = 8});

  @override
  Widget build(BuildContext context) {
    final visible = chips.isEmpty ? const <String>[] : chips.take(maxChips).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: 6,
      children: visible
          .map(
            (t) => Chip(
              label: Text(t),
              shape: const StadiumBorder(
                side: BorderSide(width: 0.8),
              ),
            ),
          )
          .toList(),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String readMoreText;
  final String readLessText;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 4,
    this.style,
    this.readMoreText = 'Read more',
    this.readLessText = 'Read less',
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) return const SizedBox.shrink();

    final effectiveMaxLines = _expanded ? null : widget.maxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: effectiveMaxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (!_expanded)
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(widget.readMoreText),
          )
        else
          TextButton(
            onPressed: () => setState(() => _expanded = false),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(widget.readLessText),
          ),
      ],
    );
  }
}

class MarketplaceEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final String refreshLabel;

  const MarketplaceEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRefresh,
    this.refreshLabel = 'Refresh',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onRefresh,
                child: Text(refreshLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MarketplaceErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const MarketplaceErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class MarketplaceShimmerSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;

  const MarketplaceShimmerSkeleton({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    // Simple shimmer approximation using animated gradient.
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.3, 0.4],
            ),
          ),
        ),
      ),
    );
  }
}

