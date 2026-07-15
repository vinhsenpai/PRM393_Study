import 'package:flutter/material.dart';

enum SkeletonLoaderType { ordersList, orderDetail }

class SkeletonLoader extends StatelessWidget {
  final SkeletonLoaderType type;

  const SkeletonLoader({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SkeletonLoaderType.ordersList:
        return _buildOrdersListSkeleton();
      case SkeletonLoaderType.orderDetail:
        return _buildOrderDetailSkeleton();
    }
  }

  Widget _buildOrdersListSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Show 6 skeleton cards
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildOrderCardSkeleton(),
    );
  }

  Widget _buildOrderDetailSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 16),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 16),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 16),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 24),
        _buildSkeletonRow(height: 16),
        const SizedBox(height: 12),
        _buildSkeletonRow(height: 16),
        const SizedBox(height: 12),
        _buildSkeletonRow(height: 16),
        const SizedBox(height: 24),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 16),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 16),
        _buildSkeletonRow(height: 20),
        const SizedBox(height: 24),
        _buildSkeletonButton(),
      ],
    );
  }

  Widget _buildOrderCardSkeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonRow(width: 120, height: 16),
                _buildSkeletonRow(width: 80, height: 16),
              ],
            ),
            const SizedBox(height: 16),
            // Product Section
            Row(
              children: [
                _buildSkeletonRow(width: 60, height: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonRow(width: 150, height: 16),
                      const SizedBox(height: 8),
                      _buildSkeletonRow(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buyer Section
            _buildSkeletonRow(width: 100, height: 16),
            const SizedBox(height: 8),
            _buildSkeletonRow(width: 150, height: 12),
            const SizedBox(height: 16),
            // Order Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonRow(width: 80, height: 16),
                _buildSkeletonRow(width: 80, height: 16),
              ],
            ),
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _buildSkeletonRow(height: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSkeletonRow(height: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonRow({
    double width = double.infinity,
    double height = 16,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}