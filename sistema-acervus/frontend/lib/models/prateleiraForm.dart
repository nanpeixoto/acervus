import 'package:flutter/material.dart';

class PrateleiraForm {
  final TextEditingController controller;

  PrateleiraForm({String descricao = ''})
      : controller = TextEditingController(text: descricao);
}
