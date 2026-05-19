import 'package:flutter/material.dart';

class PrateleiraForm {
  final int? id;

  final TextEditingController controller;

  PrateleiraForm({
    this.id,
    String descricao = '',
  }) : controller = TextEditingController(text: descricao);
}
