import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_config.dart';
import 'storage_service.dart';

class DashboardService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // =========================
  // HEADERS
  // =========================
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =========================
  // 🔹 TOTAIS (CARDS)
  // GET /dashboard/adm
  // =========================
  static Future<Map<String, dynamic>> buscarTotais() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/adm'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar totais do dashboard');
    }

    return jsonDecode(res.body);
  }

  // =========================
  // 📊 GRÁFICO – OBRAS POR ASSUNTO
  // GET /dashboard/grafico/obras-por-assunto
  // =========================
  static Future<List<dynamic>> obrasPorAssunto() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/grafico/obras-por-assunto'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar gráfico por assunto');
    }

    return jsonDecode(res.body);
  }

  // =========================
  // 📊 GRÁFICO – OBRAS POR TIPO
  // GET /dashboard/grafico/obras-por-tipo
  // =========================
  static Future<List<dynamic>> obrasPorTipo() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/grafico/obras-por-tipo'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar gráfico por tipo');
    }

    return jsonDecode(res.body);
  }

  // =========================
  // 🎬 CARROSSEL – ÚLTIMAS OBRAS
  // GET /dashboard/carrossel/obras
  // =========================
  static Future<List<dynamic>> obrasCarrossel({int limit = 15}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/carrossel/obras?limit=$limit'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar obras do carrossel');
    }

    return jsonDecode(res.body);
  }
}
