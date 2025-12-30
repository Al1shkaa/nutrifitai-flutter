import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SmartwatchScreen extends StatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  State<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends State<SmartwatchScreen> {
  bool _isConnected = false;
  String? _connectedDevice;
  bool _isSyncing = false;

  final List<Map<String, dynamic>> _availableDevices = [
    {
      'name': 'Apple Watch Series 9',
      'type': 'Apple Watch',
      'battery': 85,
      'isNearby': true,
    },
    {
      'name': 'Samsung Galaxy Watch 6',
      'type': 'Samsung',
      'battery': 72,
      'isNearby': true,
    },
    {
      'name': 'Xiaomi Mi Band 8',
      'type': 'Xiaomi',
      'battery': 45,
      'isNearby': false,
    },
  ];

  final Map<String, dynamic> _watchData = {
    'heartRate': 72,
    'steps': 8432,
    'calories': 420,
    'distance': 6.2,
    'sleep': 7.5,
    'activeMinutes': 45,
    'lastSync': '2 минуты назад',
  };

  void _toggleConnection() {
    setState(() {
      if (_isConnected) {
        _isConnected = false;
        _connectedDevice = null;
      } else {
        _isConnected = true;
        _connectedDevice = _availableDevices[0]['name'];
      }
    });
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    // Симуляция синхронизации
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
      _watchData['lastSync'] = 'Только что';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Данные успешно синхронизированы"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Смарт-часы"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.heroGradient,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionCard(),
              const SizedBox(height: 20),
              if (_isConnected) ...[
                _buildSyncButton(),
                const SizedBox(height: 20),
                _buildDataSection(),
                const SizedBox(height: 20),
              ],
              _buildDevicesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [
                  AppColors.secondary.withOpacity(0.3),
                  AppColors.secondary.withOpacity(0.1),
                ]
              : [
                  AppColors.card,
                  AppColors.cardDarker,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnected ? AppColors.secondary : AppColors.border,
          width: _isConnected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.cardDarker,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isConnected ? Icons.watch : Icons.watch_off,
                  color: _isConnected ? AppColors.secondary : AppColors.textMuted,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected ? "Подключено" : "Не подключено",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _isConnected ? AppColors.secondary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected
                          ? _connectedDevice ?? "Устройство подключено"
                          : "Подключите смарт-часы для отслеживания",
                      style: TextStyle(
                        color: _isConnected ? AppColors.textSecondary : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isConnected,
                onChanged: (_) => _toggleConnection(),
                activeColor: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSyncing ? null : _syncData,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.sync, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isSyncing ? "Синхронизация..." : "Синхронизировать данные",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Данные с часов",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDataCard(
                "Пульс",
                "${_watchData['heartRate']}",
                "уд/мин",
                Icons.favorite,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataCard(
                "Шаги",
                "${_watchData['steps']}",
                "шагов",
                Icons.directions_walk,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDataCard(
                "Калории",
                "${_watchData['calories']}",
                "ккал",
                Icons.local_fire_department,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataCard(
                "Дистанция",
                "${_watchData['distance']}",
                "км",
                Icons.straighten,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bedtime, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Сон",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_watchData['sleep']} часов",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Хорошо",
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDarker,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                "Последняя синхронизация: ${_watchData['lastSync']}",
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(String title, String value, String unit, IconData icon, Color color) {
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Доступные устройства",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableDevices.map((device) => _buildDeviceCard(device)),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final isConnected = _isConnected && _connectedDevice == device['name'];
    final isNearby = device['isNearby'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.secondary.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.secondary : AppColors.border,
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.cardDarker,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.watch,
              color: isConnected ? AppColors.secondary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? AppColors.secondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isNearby ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      size: 14,
                      color: isNearby ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isNearby ? "Рядом" : "Не в зоне доступа",
                      style: TextStyle(
                        color: isNearby ? AppColors.success : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.battery_std, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      "${device['battery']}%",
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Подключено",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isNearby)
            TextButton(
              onPressed: () {
                setState(() {
                  _isConnected = true;
                  _connectedDevice = device['name'];
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
              child: const Text("Подключить"),
            ),
        ],
      ),
    );
  }
}

