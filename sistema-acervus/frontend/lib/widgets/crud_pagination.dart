import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';

class CrudPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChange;

  const CrudPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                size: 20, color: AcervusColors.textSecondary),
            onPressed:
                currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
          ),
          ..._pageNumbers().map(
            (p) => p == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '…',
                      style: TextStyle(color: AcervusColors.textSecondary),
                    ),
                  )
                : _pagePill(p),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                size: 20, color: AcervusColors.textSecondary),
            onPressed: currentPage < totalPages
                ? () => onPageChange(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  /// Números de página com reticências: 1 … (c-1) c (c+1) … total
  List<int?> _pageNumbers() {
    if (totalPages <= 7) {
      return List<int?>.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[1];
    if (currentPage > 3) pages.add(null);
    for (var p = currentPage - 1; p <= currentPage + 1; p++) {
      if (p > 1 && p < totalPages) pages.add(p);
    }
    if (currentPage < totalPages - 2) pages.add(null);
    pages.add(totalPages);
    return pages;
  }

  Widget _pagePill(int page) {
    final isActive = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isActive ? null : () => onPageChange(page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AcervusColors.primary : null,
            borderRadius: BorderRadius.circular(8),
            border:
                isActive ? null : Border.all(color: AcervusColors.border),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : AcervusColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
