import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final String selectedFilter;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            style: const TextStyle(color: Color(0xFF0F172A)),
            cursorColor: Theme.of(context).primaryColor,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', selectedFilter, context),
              _buildFilterChip('Pending', selectedFilter, context),
              _buildFilterChip('Processing', selectedFilter, context),
              _buildFilterChip('Completed', selectedFilter, context),
              _buildFilterChip('Cancelled', selectedFilter, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedFilter, BuildContext context) {
    final bool isSelected = label == selectedFilter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(label);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF334155),
        ),
      ),
    );
  }
}