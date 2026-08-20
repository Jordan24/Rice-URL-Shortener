import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../state/link_controller.dart';

class LinkSearchBar extends StatelessWidget {
  final String searchQuery;
  final LinkStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LinkStatusFilter> onStatusChanged;

  const LinkSearchBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search short codes or destination URLs...",
                      prefixIcon: const Icon(Icons.search, color: RiceColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: RiceColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: RiceColors.borderLight),
                      ),
                    ),
                  ),
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: 16),
                  _buildFilterChips(),
                ],
              ],
            ),
            if (isNarrow) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: _buildFilterChips()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip("All", LinkStatusFilter.all),
        const SizedBox(width: 8),
        _buildChip("Active", LinkStatusFilter.active),
        const SizedBox(width: 8),
        _buildChip("Expired", LinkStatusFilter.expired),
      ],
    );
  }

  Widget _buildChip(String label, LinkStatusFilter filter) {
    final isSelected = statusFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onStatusChanged(filter),
      selectedColor: RiceColors.riceBlue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : RiceColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? RiceColors.riceBlue : RiceColors.borderLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
