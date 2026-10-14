import 'package:flutter/material.dart';

class HomeShimmerLoading extends StatelessWidget {
  final bool isDark;

  const HomeShimmerLoading({super.key, required this.isDark});

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26223D) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header Shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 140, height: 12),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 200, height: 22, borderRadius: 8),
              ],
            ),
            Row(
              children: [
                _buildShimmerBox(width: 44, height: 44, borderRadius: 14),
                const SizedBox(width: 8),
                _buildShimmerBox(width: 44, height: 44, borderRadius: 14),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar Shimmer
        _buildShimmerBox(width: double.infinity, height: 46, borderRadius: 14),
        const SizedBox(height: 18),

        // Bento Grid Shimmer (2x2)
        Row(
          children: [
            Expanded(child: _buildShimmerBox(width: double.infinity, height: 110, borderRadius: 18)),
            const SizedBox(width: 10),
            Expanded(child: _buildShimmerBox(width: double.infinity, height: 110, borderRadius: 18)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildShimmerBox(width: double.infinity, height: 110, borderRadius: 18)),
            const SizedBox(width: 10),
            Expanded(child: _buildShimmerBox(width: double.infinity, height: 110, borderRadius: 18)),
          ],
        ),
        const SizedBox(height: 20),

        // Services Grid Shimmer (8 items)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) => Column(
            children: [
              _buildShimmerBox(width: 52, height: 52, borderRadius: 16),
              const SizedBox(height: 6),
              _buildShimmerBox(width: 44, height: 10, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Carousel Shimmer
        _buildShimmerBox(width: double.infinity, height: 130, borderRadius: 20),
      ],
    );
  }
}
