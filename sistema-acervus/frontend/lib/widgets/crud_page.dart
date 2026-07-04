import 'package:flutter/material.dart';

import '../theme/acervus_colors.dart';
import 'loading_overlay.dart';

class CrudPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String addLabel;
  final bool isLoading;
  final VoidCallback onAdd;
  final Widget header;
  final Widget? form;
  final Widget list;
  final Widget pagination;

  const CrudPage({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onAdd,
    required this.header,
    required this.list,
    required this.pagination,
    this.form,
    this.subtitle,
    this.addLabel = 'Novo',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcervusColors.background,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AcervusColors.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AcervusColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(addLabel),
                    ),
                  ],
                ),
              ),
              header,
              if (form != null) form!,
              list,
              pagination,
            ],
          ),
        ),
      ),
    );
  }
}
