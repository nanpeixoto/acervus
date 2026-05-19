import 'package:flutter/material.dart';
import 'loading_overlay.dart';

class CrudPage extends StatelessWidget {
  final String title;
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
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
