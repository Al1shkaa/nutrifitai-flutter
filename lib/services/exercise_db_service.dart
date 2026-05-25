import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../api/api_client.dart';

class ExerciseDbService {
  static List<Map<String, dynamic>>? _cache;

  static Future<List<Map<String, dynamic>>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/exercises.json');
      _cache = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _cache = [];
    }
    return _cache!;
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

  static Future<Map<String, dynamic>?> findByName(String nameEn) async {
    final list = await _load();
    final target = _normalize(nameEn);
    if (target.isEmpty || list.isEmpty) return null;

    for (final ex in list) {
      if (_normalize(ex['name']?.toString() ?? '') == target) return ex;
    }
    final words = target.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty) return null;
    for (final ex in list) {
      final n = _normalize(ex['name']?.toString() ?? '');
      if (words.every((w) => n.contains(w))) return ex;
    }
    Map<String, dynamic>? best;
    int bestScore = 0;
    for (final ex in list) {
      final n = _normalize(ex['name']?.toString() ?? '');
      final score = words.where((w) => n.contains(w)).length;
      if (score > bestScore && score >= (words.length / 2).ceil()) {
        bestScore = score;
        best = ex;
      }
    }
    return best;
  }

  static String imageUrl(String relativePath) =>
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$relativePath';

  static const Map<String, String> _muscleRu = {
    'abdominals': 'Пресс',
    'abductors': 'Отводящие мышцы',
    'adductors': 'Приводящие мышцы',
    'biceps': 'Бицепс',
    'calves': 'Икры',
    'chest': 'Грудь',
    'forearms': 'Предплечья',
    'glutes': 'Ягодицы',
    'hamstrings': 'Бицепс бедра',
    'lats': 'Широчайшие',
    'lower back': 'Поясница',
    'middle back': 'Средняя часть спины',
    'neck': 'Шея',
    'quadriceps': 'Квадрицепс',
    'shoulders': 'Плечи',
    'traps': 'Трапеция',
    'triceps': 'Трицепс',
  };

  static String muscleRu(String m) => _muscleRu[m.toLowerCase()] ?? m;

  static final Map<String, List<String>> _trCache = {};

  static Future<List<String>> translateInstructions(
      String cacheKey, List<String> english) async {
    if (english.isEmpty) return [];
    if (_trCache.containsKey(cacheKey)) return _trCache[cacheKey]!;
    try {
      final numbered = [
        for (int i = 0; i < english.length; i++) '${i + 1}. ${english[i]}'
      ].join('\n');
      final resp = await ApiClient.dio.post('/ai/recommend', data: {
        'prompt': 'Переведи на русский эти инструкции по технике упражнения. '
            'Верни ТОЛЬКО перевод: каждый пункт с новой строки, в том же '
            'порядке и с теми же номерами, без пояснений и без markdown:\n'
            '$numbered',
        'withPersonalData': false,
      });
      final text = (resp.data['recommendation'] ?? '').toString();
      final lines = text
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final result = lines.length >= english.length ? lines : english;
      _trCache[cacheKey] = result;
      return result;
    } catch (e) {
      return english;
    }
  }
}
