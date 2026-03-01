import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/figure.dart';

/// 角色数据加载服务
class FigureService {
  static const String _assetPath = 'assets/figure_image/figures.json';

  static List<String> _categories = [];
  static List<Figure> _figures = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final json = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    _categories = (map['categories'] as List).cast<String>();
    _figures = (map['figures'] as List)
        .map((e) => Figure.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  static List<String> get categories => _categories;

  static List<Figure> get figures => _figures;

  static List<Figure> getFiguresByCategory(String category) {
    return _figures.where((f) => f.category == category).toList();
  }

  static Figure? getFigureById(String id) {
    try {
      return _figures.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
