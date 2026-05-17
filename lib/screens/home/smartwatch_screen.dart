import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import '../../theme/app_colors.dart';

class SmartwatchScreen extends StatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  State<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends State<SmartwatchScreen> {
  final _service = HealthService();

  int _steps = 0;
  int? _heartRate;
  double _calories = 0;
  double _distanceMeters = 0;
  int _sleepMinutes = 0;
  bool _isLoading = true;
  bool _hasPermissions = false;
  String? _error;

  static const int _stepsGoal = 10000;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _service.configure();
    final granted = await _service.requestAndroidPermissions();
    if (!granted) {
      setState(() {
        _error = 'Требуется разрешение на физическую активность';
        _isLoading = false;
      });
      return;
    }

    // Стандартный запрос (работает на Android 14+)
    var hcGranted = await _service.requestHealthPermissions();

    // Если не сработало — проверим, может разрешения уже даны вручную
    if (!hcGranted) {
      hcGranted = await _service.hasPermissions();
    }

    setState(() => _hasPermissions = hcGranted);
    if (hcGranted) {
      await _loadData();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getTodaySteps(),
        _service.getLatestHeartRate(),
        _service.getTodayCalories(),
        _service.getTodayDistance(),
        _service.getTodaySleep(),
      ]);
      if (mounted) {
        setState(() {
          _steps = results[0] as int;
          _heartRate = results[1] as int?;
          _calories = results[2] as double;
          _distanceMeters = results[3] as double;
          _sleepMinutes = results[4] as int;
        });
      }
    } catch (e) {
      print('Health data error: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активность'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.heroGradient,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : !_hasPermissions
                ? _buildNoPermissionsView()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepsHero(),
                          const SizedBox(height: 16),
                          _buildMetricsGrid(),
                          const SizedBox(height: 16),
                          _buildSourceCard(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildNoPermissionsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет доступа к Health Connect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Откройте Health Connect и разрешите доступ для NutriFit AI. После этого вернитесь и нажмите «Проверить доступ».',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _service.openHealthConnectSettings(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Открыть Health Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh),
                label: const Text('Проверить доступ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsHero() {
    final progress = (_steps / _stepsGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_walk,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_steps',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'шагов сегодня',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${(_steps / _stepsGoal * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                'Цель: ${_stepsGoal.toString()} шагов',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                '$_stepsGoal',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Пульс',
          value: _heartRate != null ? '$_heartRate' : '—',
          unit: 'уд/мин',
          icon: Icons.favorite,
          color: AppColors.error,
        ),
        _buildMetricCard(
          title: 'Калории',
          value: _calories.toStringAsFixed(0),
          unit: 'ккал',
          icon: Icons.local_fire_department,
          color: AppColors.warning,
        ),
        _buildMetricCard(
          title: 'Расстояние',
          value: (_distanceMeters / 1000).toStringAsFixed(2),
          unit: 'км',
          icon: Icons.directions_run,
          color: AppColors.secondary,
        ),
        _buildMetricCard(
          title: 'Сон',
          value: _sleepMinutes > 0 ? '${_sleepMinutes ~/ 60}ч ${_sleepMinutes % 60}м' : '—',
          unit: '',
          icon: Icons.bedtime,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.watch_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Источник данных',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'FAIZ W7 Ultimate через HawoFit + Health Connect',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
