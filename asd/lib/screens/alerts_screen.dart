import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
enum AlertType { spoiled, danger, sensor }

class AlertItem {
  final String title;
  final String description;
  final String time;
  final AlertType type;

  const AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    AlertType t;
    switch ((json['type'] ?? '').toLowerCase()) {
      case 'spoiled': t = AlertType.spoiled; break;
      case 'danger':  t = AlertType.danger;  break;
      default:        t = AlertType.sensor;
    }
    return AlertItem(
      title:       json['title']       ?? '',
      description: json['description'] ?? '',
      time:        json['time']        ?? '',
      type:        t,
    );
  }

  Color get borderColor {
    switch (type) {
      case AlertType.spoiled: return AppColors.spoiledColor;
      case AlertType.danger:  return AppColors.dangerColor;
      case AlertType.sensor:  return AppColors.medium;
    }
  }

  Color get bgColor {
    switch (type) {
      case AlertType.spoiled: return AppColors.spoiledBg;
      case AlertType.danger:  return AppColors.dangerBg;
      case AlertType.sensor:  return AppColors.surfaceAlt;
    }
  }

  Color get iconBg {
    switch (type) {
      case AlertType.spoiled: return const Color(0xFFF5D5D5);
      case AlertType.danger:  return const Color(0xFFF5E5C8);
      case AlertType.sensor:  return const Color(0xFFD6E4EC);
    }
  }

  Color get iconColor {
    switch (type) {
      case AlertType.spoiled: return AppColors.spoiledColor;
      case AlertType.danger:  return AppColors.dangerColor;
      case AlertType.sensor:  return AppColors.medium;
    }
  }

  Color get titleColor {
    switch (type) {
      case AlertType.spoiled: return AppColors.spoiledText;
      case AlertType.danger:  return AppColors.dangerText;
      case AlertType.sensor:  return AppColors.textPrimary;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.spoiled: return Icons.warning_rounded;
      case AlertType.danger:  return Icons.access_time_rounded;
      case AlertType.sensor:  return Icons.thermostat_rounded;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertItem> _alerts = [];
  bool _loading = true;
  String? _error;

  String get _apiUrl => kIsWeb
      ? 'http://localhost/freshguard/get_alerts.php'
      : 'http://10.0.2.2/freshguard/get_alerts.php';

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _alerts = data.map((j) => AlertItem.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not reach server.\n$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spoiled = _alerts.where((a) => a.type == AlertType.spoiled).length;
    final danger  = _alerts.where((a) => a.type == AlertType.danger).length;
    final sensor  = _alerts.where((a) => a.type == AlertType.sensor).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (_alerts.isNotEmpty)
                  Text('${_alerts.length}', style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _fetchAlerts,
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textSub),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetchAlerts)
              : _alerts.isEmpty
                  ? const Center(
                      child: Text('No alerts — everything looks fresh!',
                          style: TextStyle(color: AppColors.textSub)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                        // ── Summary cards ──────────────────────────
                        Row(
                          children: [
                            _CountCard(count: spoiled, label: 'Spoiled', bg: AppColors.spoiledBg, numColor: AppColors.spoiledText, lblColor: const Color(0xFFA04040)),
                            const SizedBox(width: 8),
                            _CountCard(count: danger,  label: 'Danger',  bg: AppColors.dangerBg,  numColor: AppColors.dangerText,  lblColor: const Color(0xFF8B6820)),
                            const SizedBox(width: 8),
                            _CountCard(count: sensor,  label: 'Sensor',  bg: AppColors.surfaceAlt, numColor: AppColors.textPrimary, lblColor: AppColors.textSub),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const SectionLabel('All alerts'),

                        ..._alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AlertCard(alert: alert),
                        )),
                      ],
                    ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count Card ────────────────────────────────────────────────────────────────
class _CountCard extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color numColor;
  final Color lblColor;

  const _CountCard({
    required this.count, required this.label,
    required this.bg, required this.numColor, required this.lblColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: numColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: lblColor)),
          ],
        ),
      ),
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: alert.borderColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: alert.iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(alert.icon, size: 18, color: alert.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: alert.titleColor)),
                const SizedBox(height: 3),
                Text(alert.description,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.4)),
                const SizedBox(height: 5),
                Text(alert.time,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}