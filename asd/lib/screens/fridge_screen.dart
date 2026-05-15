import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';

// ── API config ────────────────────────────────────────────────────────────────
// Use 10.0.2.2 for Android emulator (maps to localhost on host machine)
// Use your actual LAN IP (e.g. 192.168.1.x) for a real device
import 'package:flutter/foundation.dart' show kIsWeb;

String get _apiUrl {
  if (kIsWeb) {
    return 'http://localhost/freshguard/get_items.php';
  }
  return 'http://10.0.2.2/freshguard/get_items.php'; // Android emulator
}

// ── Model from DB ─────────────────────────────────────────────────────────────
class PredictionItem {
  final int id;
  final String itemName;
  final String type;
  final int oldTemp;
  final int newTemp;
  final int humidity;
  final int initialLife;
  final int timeBeforeTimeInBetween;
  final int lifeRemaining;
  final String status;
  final int? itemNameVal;
  final int? typeVal;
  final double? oldDecay;
  final double? spikeDamage;

  const PredictionItem({
    required this.id,
    required this.itemName,
    required this.type,
    required this.oldTemp,
    required this.newTemp,
    required this.humidity,
    required this.initialLife,
    required this.timeBeforeTimeInBetween,
    required this.lifeRemaining,
    required this.status,
    this.itemNameVal,
    this.typeVal,
    this.oldDecay,
    this.spikeDamage,
  });

  factory PredictionItem.fromJson(Map<String, dynamic> json) {
    return PredictionItem(
      id:                       int.parse(json['id'].toString()),
      itemName:                 json['item_name'] ?? '',
      type:                     json['type'] ?? '',
      oldTemp:                  int.parse(json['old_temp'].toString()),
      newTemp:                  int.parse(json['new_temp'].toString()),
      humidity:                 int.parse(json['humidity'].toString()),
      initialLife:              int.parse(json['initial_life'].toString()),
      timeBeforeTimeInBetween:  int.parse(json['time_before_time_in_between'].toString()),
      lifeRemaining:            int.parse(json['life_remaining'].toString()),
      status:                   json['status'] ?? '',
      itemNameVal:              json['item_name_val'] != null ? int.parse(json['item_name_val'].toString()) : null,
      typeVal:                  json['type_val'] != null ? int.parse(json['type_val'].toString()) : null,
      oldDecay:                 json['old_decay'] != null ? double.parse(json['old_decay'].toString()) : null,
      spikeDamage:              json['spike_damage'] != null ? double.parse(json['spike_damage'].toString()) : null,
    );
  }

  // ── Derived helpers ────────────────────────────────────────────
  double get freshnessFraction =>
      initialLife > 0 ? (lifeRemaining / initialLife).clamp(0.0, 1.0) : 0.0;

  FridgeStatus get fridgeStatus {
    switch (status.toLowerCase()) {
      case 'good':       return FridgeStatus.good;
      case 'acceptable': return FridgeStatus.acceptable;
      case 'danger':     return FridgeStatus.danger;
      case 'spoiled':    return FridgeStatus.spoiled;
      default:
        if (lifeRemaining <= 0)                          return FridgeStatus.spoiled;
        if (lifeRemaining / initialLife < 0.2)           return FridgeStatus.danger;
        if (lifeRemaining / initialLife < 0.5)           return FridgeStatus.acceptable;
        return FridgeStatus.good;
    }
  }

  Color get statusColor {
    switch (fridgeStatus) {
      case FridgeStatus.good:       return AppColors.medium;
      case FridgeStatus.acceptable: return AppColors.light;
      case FridgeStatus.danger:     return AppColors.dangerColor;
      case FridgeStatus.spoiled:    return AppColors.spoiledColor;
    }
  }

  Color get badgeBg {
    switch (fridgeStatus) {
      case FridgeStatus.good:       return AppColors.goodBg;
      case FridgeStatus.acceptable: return AppColors.acceptBg;
      case FridgeStatus.danger:     return AppColors.dangerBg;
      case FridgeStatus.spoiled:    return AppColors.spoiledBg;
    }
  }

  Color get badgeText {
    switch (fridgeStatus) {
      case FridgeStatus.good:       return AppColors.goodText;
      case FridgeStatus.acceptable: return AppColors.acceptText;
      case FridgeStatus.danger:     return AppColors.dangerText;
      case FridgeStatus.spoiled:    return AppColors.spoiledText;
    }
  }

  String get statusLabel {
    switch (fridgeStatus) {
      case FridgeStatus.good:       return 'Good';
      case FridgeStatus.acceptable: return 'Acceptable';
      case FridgeStatus.danger:     return 'Danger';
      case FridgeStatus.spoiled:    return 'Spoiled';
    }
  }

  String get daysLabel {
    if (fridgeStatus == FridgeStatus.spoiled) return 'Expired';
    if (lifeRemaining < 24) return '${lifeRemaining}h left';
    final days = (lifeRemaining / 24).toStringAsFixed(1);
    return '$days days left';
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'vegetable':   return Icons.grass_rounded;
      case 'fruit':       return Icons.energy_savings_leaf_rounded;
      case 'dairy':       return Icons.water_drop_outlined;
      case 'meat':        return Icons.restaurant_rounded;
      case 'herb':        return Icons.eco_rounded;
      case 'grain':       return Icons.grain_rounded;
      case 'condiment':   return Icons.local_dining_rounded;
      case 'beverage':    return Icons.local_drink_rounded;
      default:            return Icons.kitchen_rounded;
    }
  }
}

enum FridgeStatus { good, acceptable, danger, spoiled }

// ── Category metadata ─────────────────────────────────────────────────────────
const Map<String, IconData> categoryIcons = {
  'vegetable':  Icons.grass_rounded,
  'fruit':      Icons.energy_savings_leaf_rounded,
  'dairy':      Icons.water_drop_outlined,
  'meat':       Icons.restaurant_rounded,
  'herb':       Icons.eco_rounded,
  'grain':      Icons.grain_rounded,
  'condiment':  Icons.local_dining_rounded,
  'beverage':   Icons.local_drink_rounded,
};

const List<String> categoryOrder = [
  'vegetable', 'fruit', 'herb', 'meat', 'dairy', 'grain', 'condiment', 'beverage',
];

// ── Fridge Screen ─────────────────────────────────────────────────────────────
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  List<PredictionItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _items = data.map((j) => PredictionItem.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not reach server.\n$e'; _loading = false; });
    }
  }

  void _showItemDetail(BuildContext context, PredictionItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dangerCount  = _items.where((i) => i.fridgeStatus == FridgeStatus.danger).length;
    final spoiledCount = _items.where((i) => i.fridgeStatus == FridgeStatus.spoiled).length;
    final goodCount    = _items.where((i) => i.fridgeStatus == FridgeStatus.good).length;

    // Group by type
    final Map<String, List<PredictionItem>> grouped = {};
    for (final cat in categoryOrder) {
      final items = _items.where((i) => i.type.toLowerCase() == cat).toList();
      if (items.isNotEmpty) grouped[cat] = items;
    }
    for (final item in _items) {
      if (!grouped.containsKey(item.type.toLowerCase())) {
        grouped[item.type.toLowerCase()] =
            _items.where((i) => i.type.toLowerCase() == item.type.toLowerCase()).toList();
      }
    }
    final categories = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fridge'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('${_items.length} items',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _fetchItems,
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textSub),
                ),
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
              ? _ErrorView(message: _error!, onRetry: _fetchItems)
              : _items.isEmpty
                  ? const Center(
                      child: Text('No items found', style: TextStyle(color: AppColors.textSub)),
                    )
                  : CustomScrollView(
                      slivers: [
                        // ── Summary row ──────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Row(
                              children: [
                                _SummaryChip(count: dangerCount,  label: 'Danger',  bg: AppColors.dangerBg,  textColor: AppColors.dangerText),
                                const SizedBox(width: 8),
                                _SummaryChip(count: spoiledCount, label: 'Spoiled', bg: AppColors.spoiledBg, textColor: AppColors.spoiledText),
                                const SizedBox(width: 8),
                                _SummaryChip(count: goodCount,    label: 'Good',    bg: AppColors.goodBg,    textColor: AppColors.goodText),
                              ],
                            ),
                          ),
                        ),

                        // ── Category sections ────────────────────────
                        for (final category in categories) ...[
                          SliverToBoxAdapter(
                            child: _CategoryHeader(
                              category: category,
                              count: grouped[category]!.length,
                              icon: categoryIcons[category] ?? Icons.category_rounded,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = grouped[category]![index];
                                  return _FridgeGridItem(
                                    item: item,
                                    onTap: () => _showItemDetail(context, item),
                                  );
                                },
                                childCount: grouped[category]!.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.88,
                              ),
                            ),
                          ),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
            Text(message,
                textAlign: TextAlign.center,
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

// ── Category Header ───────────────────────────────────────────────────────────
class _CategoryHeader extends StatelessWidget {
  final String category;
  final int count;
  final IconData icon;

  const _CategoryHeader({required this.category, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: AppColors.medium),
          ),
          const SizedBox(width: 8),
          Text(
            category[0].toUpperCase() + category.substring(1) + 's',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textSub, letterSpacing: 0.8),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Grid Item ─────────────────────────────────────────────────────────────────
class _FridgeGridItem extends StatelessWidget {
  final PredictionItem item;
  final VoidCallback onTap;

  const _FridgeGridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: item.statusColor, shape: BoxShape.circle),
                      ),
                    ),
                    Center(child: Icon(item.icon, size: 36, color: AppColors.medium)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: Text(
                item.itemName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color textColor;

  const _SummaryChip({required this.count, required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

// ── Item Detail Bottom Sheet ──────────────────────────────────────────────────
class _ItemDetailSheet extends StatelessWidget {
  final PredictionItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, size: 28, color: AppColors.medium),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(item.type,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                  ],
                ),
              ),
              StatusBadge(label: item.statusLabel, bg: item.badgeBg, textColor: item.badgeText),
            ],
          ),

          const SizedBox(height: 20),

          // Freshness bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Life remaining', style: TextStyle(fontSize: 12, color: AppColors.textSub)),
              Text(item.daysLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: item.statusColor)),
            ],
          ),
          const SizedBox(height: 6),
          FreshnessBar(fraction: item.freshnessFraction, color: item.statusColor, height: 6),

          const SizedBox(height: 20),

          // Info rows — all DB fields
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _InfoRow(label: 'Previous Temp',   value: '${item.oldTemp}°C'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Current Temp',    value: '${item.newTemp}°C'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Humidity',        value: '${item.humidity}%'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Initial Life',    value: '${item.initialLife}h'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Time Interval',   value: '${item.timeBeforeTimeInBetween}h'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Life Remaining',  value: '${item.lifeRemaining}h'),
                if (item.oldDecay != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Decay Rate',    value: item.oldDecay!.toStringAsFixed(4)),
                ],
                if (item.spikeDamage != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Spike Damage',  value: item.spikeDamage!.toStringAsFixed(4)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
        Text(value,  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }
}