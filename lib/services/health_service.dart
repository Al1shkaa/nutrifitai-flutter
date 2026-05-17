import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
  ];

  static final List<HealthDataAccess> _permissions =
      _types.map((e) => HealthDataAccess.READ).toList();

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestAndroidPermissions() async {
    final activity = await Permission.activityRecognition.request();
    await Permission.sensors.request();
    return activity.isGranted;
  }

  /// Проверяет есть ли уже разрешения (без запроса)
  Future<bool> hasPermissions() async {
    try {
      final result = await _health.hasPermissions(_types, permissions: _permissions);
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Пытается запросить разрешения через стандартный API.
  /// На Android < 14 может не сработать — тогда возвращает false.
  Future<bool> requestHealthPermissions() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        print('Health Connect SDK not available: $status');
        return false;
      }
      final already = await hasPermissions();
      if (already) return true;
      final ok = await _health.requestAuthorization(_types, permissions: _permissions);
      return ok;
    } catch (e) {
      print('requestHealthPermissions error: $e');
      return false;
    }
  }

  /// Открывает экран разрешений Health Connect через Android Intent
  Future<void> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.VIEW_PERMISSION_USAGE',
        package: 'com.google.android.apps.healthdata',
        category: 'android.intent.category.HEALTH_PERMISSIONS',
      );
      await intent.launch();
    } catch (e) {
      print('Intent launch failed: $e');
      try {
        const fallback = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.google.android.apps.healthdata',
        );
        await fallback.launch();
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
    }
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(midnight, now);
    return steps ?? 0;
  }

  Future<int?> getLatestHeartRate() async {
    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(hours: 24));

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE],
      startTime: dayAgo,
      endTime: now,
    );

    final allData = [...data];

    try {
      final restingData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: dayAgo,
        endTime: now,
      );
      allData.addAll(restingData);
    } catch (e) {
      print('Resting HR not available: $e');
    }

    if (allData.isEmpty) {
      print('No heart rate data found in last 24h');
      return null;
    }

    allData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    print('Latest HR record: ${allData.first.value} at ${allData.first.dateTo}');
    final value = allData.first.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toInt();
    }
    return null;
  }

  Future<double> getTodayCalories() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: midnight,
      endTime: now,
    );
    double sum = 0.0;
    for (final d in data) {
      if (d.value is NumericHealthValue) {
        sum += (d.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return sum;
  }

  Future<double> getTodayDistance() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.DISTANCE_DELTA],
      startTime: midnight,
      endTime: now,
    );
    double sum = 0.0;
    for (final d in data) {
      if (d.value is NumericHealthValue) {
        sum += (d.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return sum;
  }
}
