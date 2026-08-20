import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../state/link_controller.dart';

class LinkSearchBar extends StatefulWidget {
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
  State<LinkSearchBar> createState() => _LinkSearchBarState();
}

class _LinkSearchBarState extends State<LinkSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant LinkSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                    controller: _controller,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search short codes or destination URLs...",
                      prefixIcon: const Icon(Icons.search, color: RiceColors.textSecondary, size: 20),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: RiceColors.textSecondary, size: 18),
                              onPressed: () {
                                _controller.clear();
                                widget.onSearchChanged('');
                              },
                              tooltip: 'Clear search',
                            )
                          : null,
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
    final isSelected = widget.statusFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => widget.onStatusChanged(filter),
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
