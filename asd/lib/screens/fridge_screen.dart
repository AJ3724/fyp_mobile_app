import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';

// ── API config ────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart' show kIsWeb;

String get _apiUrl {
  if (kIsWeb) return 'http://localhost/freshguard/get_items.php';
  return 'http://10.0.2.2/freshguard/get_items.php';
}

// ── Model ─────────────────────────────────────────────────────────────────────
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
      id: int.parse(json['id'].toString()),
      itemName: json['item_name'] ?? '',
      type: json['type'] ?? '',
      oldTemp: int.parse(json['old_temp'].toString()),
      newTemp: int.parse(json['new_temp'].toString()),
      humidity: int.parse(json['humidity'].toString()),
      initialLife: int.parse(json['initial_life'].toString()),
      timeBeforeTimeInBetween: int.parse(json['time_before_time_in_between'].toString()),
      lifeRemaining: int.parse(json['life_remaining'].toString()),
      status: json['status'] ?? '',
      itemNameVal: json['item_name_val'] != null ? int.parse(json['item_name_val'].toString()) : null,
      typeVal: json['type_val'] != null ? int.parse(json['type_val'].toString()) : null,
      oldDecay: json['old_decay'] != null ? double.parse(json['old_decay'].toString()) : null,
      spikeDamage: json['spike_damage'] != null ? double.parse(json['spike_damage'].toString()) : null,
    );
  }

  double get freshnessFraction =>
      initialLife > 0 ? (lifeRemaining / initialLife).clamp(0.0, 1.0) : 0.0;

  FridgeStatus get fridgeStatus {
    switch (status.toLowerCase()) {
      case 'good': return FridgeStatus.good;
      case 'acceptable': return FridgeStatus.acceptable;
      case 'danger': return FridgeStatus.danger;
      case 'spoiled': return FridgeStatus.spoiled;
      default:
        if (lifeRemaining <= 0) return FridgeStatus.spoiled;
        if (lifeRemaining / initialLife < 0.2) return FridgeStatus.danger;
        if (lifeRemaining / initialLife < 0.5) return FridgeStatus.acceptable;
        return FridgeStatus.good;
    }
  }

  Color get statusColor {
    switch (fridgeStatus) {
      case FridgeStatus.good: return AppColors.medium;
      case FridgeStatus.acceptable: return AppColors.light;
      case FridgeStatus.danger: return AppColors.dangerColor;
      case FridgeStatus.spoiled: return AppColors.spoiledColor;
    }
  }

  Color get badgeBg {
    switch (fridgeStatus) {
      case FridgeStatus.good: return AppColors.goodBg;
      case FridgeStatus.acceptable: return AppColors.acceptBg;
      case FridgeStatus.danger: return AppColors.dangerBg;
      case FridgeStatus.spoiled: return AppColors.spoiledBg;
    }
  }

  Color get badgeText {
    switch (fridgeStatus) {
      case FridgeStatus.good: return AppColors.goodText;
      case FridgeStatus.acceptable: return AppColors.acceptText;
      case FridgeStatus.danger: return AppColors.dangerText;
      case FridgeStatus.spoiled: return AppColors.spoiledText;
    }
  }

  String get statusLabel {
    switch (fridgeStatus) {
      case FridgeStatus.good: return 'Good';
      case FridgeStatus.acceptable: return 'Acceptable';
      case FridgeStatus.danger: return 'Danger';
      case FridgeStatus.spoiled: return 'Spoiled';
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
      case 'vegetable': return Icons.grass_rounded;
      case 'fruit': return Icons.energy_savings_leaf_rounded;
      case 'dairy': return Icons.water_drop_outlined;
      case 'meat': return Icons.restaurant_rounded;
      case 'herb': return Icons.eco_rounded;
      case 'grain': return Icons.grain_rounded;
      case 'condiment': return Icons.local_dining_rounded;
      case 'beverage': return Icons.local_drink_rounded;
      default: return Icons.kitchen_rounded;
    }
  }
}

enum FridgeStatus { good, acceptable, danger, spoiled }

// ── Category metadata ─────────────────────────────────────────────────────────
const Map<String, IconData> categoryIcons = {
  'vegetable': Icons.grass_rounded,
  'fruit': Icons.energy_savings_leaf_rounded,
  'dairy': Icons.water_drop_outlined,
  'meat': Icons.restaurant_rounded,
  'herb': Icons.eco_rounded,
  'grain': Icons.grain_rounded,
  'condiment': Icons.local_dining_rounded,
  'beverage': Icons.local_drink_rounded,
};

const List<String> categoryOrder = [
  'vegetable', 'fruit', 'herb', 'meat', 'dairy', 'grain', 'condiment', 'beverage',
];

// ── Fridge design constants ───────────────────────────────────────────────────
class FridgeColors {
  // Fridge outer shell
  static const Color outerWall       = Color(0xFFD8E8DF);
  // Interior walls — cool white with very slight blue tint
  static const Color interiorWall    = Color(0xFFECF5F1);
  static const Color interiorSide    = Color(0xFFDCECE5);
  // Shelf glass
  static const Color shelfGlass      = Color(0xFFB8D8C8);
  static const Color shelfEdge       = Color(0xFF8DBCAA);
  static const Color shelfShadow     = Color(0x22000000);
  // Interior lighting glow at top
  static const Color lightGlow       = Color(0xFFEFFFFA);
  static const Color lightStrip      = Color(0xFFD0F0E4);
  // Card background — frosted feel
  static const Color cardBg          = Color(0xFFF5FBFF);
  static const Color cardBorder      = Color(0xFFCCE4D8);
  // Shelf label pill
  static const Color shelfLabelBg    = Color(0xFFCCE8DA);
  static const Color shelfLabelText  = Color(0xFF1A5C3A);
  // Fridge inner shadow on sides
  static const Color sideDepth       = Color(0x18000000);
}

// ── Main Screen ───────────────────────────────────────────────────────────────
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

  Map<String, List<PredictionItem>> _buildGrouped() {
    final Map<String, List<PredictionItem>> grouped = {};
    for (final cat in categoryOrder) {
      final items = _items.where((i) => i.type.toLowerCase() == cat).toList();
      if (items.isNotEmpty) grouped[cat] = items;
    }
    for (final item in _items) {
      final k = item.type.toLowerCase();
      if (!grouped.containsKey(k)) {
        grouped[k] = _items.where((i) => i.type.toLowerCase() == k).toList();
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final dangerCount  = _items.where((i) => i.fridgeStatus == FridgeStatus.danger).length;
    final spoiledCount = _items.where((i) => i.fridgeStatus == FridgeStatus.spoiled).length;
    final goodCount    = _items.where((i) => i.fridgeStatus == FridgeStatus.good).length;
    final grouped      = _buildGrouped();
    final categories   = grouped.keys.toList();

    return Scaffold(
      backgroundColor: FridgeColors.outerWall,
      appBar: AppBar(
        backgroundColor: FridgeColors.outerWall,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(Icons.kitchen_rounded, size: 18, color: AppColors.textSub),
            const SizedBox(width: 8),
            const Text('My Fridge'),
          ],
        ),
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
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetchItems)
              : _items.isEmpty
                  ? const Center(child: Text('No items found', style: TextStyle(color: AppColors.textSub)))
                  : _FridgeInterior(
                      dangerCount: dangerCount,
                      spoiledCount: spoiledCount,
                      goodCount: goodCount,
                      grouped: grouped,
                      categories: categories,
                      onItemTap: (item) => _showItemDetail(context, item),
                    ),
    );
  }
}

// ── Fridge Interior Layout ────────────────────────────────────────────────────
class _FridgeInterior extends StatelessWidget {
  final int dangerCount;
  final int spoiledCount;
  final int goodCount;
  final Map<String, List<PredictionItem>> grouped;
  final List<String> categories;
  final void Function(PredictionItem) onItemTap;

  const _FridgeInterior({
    required this.dangerCount,
    required this.spoiledCount,
    required this.goodCount,
    required this.grouped,
    required this.categories,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fridge outer bezel / door frame
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: FridgeColors.interiorSide,
        borderRadius: BorderRadius.circular(18),
        // Inset shadow to simulate interior depth on sides
        boxShadow: [
          BoxShadow(color: FridgeColors.sideDepth, blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: FridgeColors.shelfEdge.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // ── Interior back wall ──────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _FridgeWallPainter()),
            ),

            // ── Content scroll ──────────────────────────────────────────────
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── Top light strip ───────────────────────────────────────
                  _LightStrip(),

                  // ── Shelf 0: Status dashboard ─────────────────────────────
                  _FridgeShelf(
                    label: 'Overview',
                    labelIcon: Icons.dashboard_rounded,
                    isFirst: true,
                    child: _StatusShelfContent(
                      dangerCount: dangerCount,
                      spoiledCount: spoiledCount,
                      goodCount: goodCount,
                      total: dangerCount + spoiledCount + goodCount,
                    ),
                  ),

                  // ── One shelf per category ────────────────────────────────
                  for (final category in categories)
                    _FridgeShelf(
                      label: '${category[0].toUpperCase()}${category.substring(1)}s',
                      labelIcon: categoryIcons[category] ?? Icons.category_rounded,
                      count: grouped[category]!.length,
                      child: _CategoryShelfContent(
                        items: grouped[category]!,
                        onTap: onItemTap,
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Left side depth shadow ───────────────────────────────────────
            Positioned(
              top: 0, left: 0, bottom: 0,
              width: 10,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FridgeColors.sideDepth, Colors.transparent],
                  ),
                ),
              ),
            ),
            // ── Right side depth shadow ──────────────────────────────────────
            Positioned(
              top: 0, right: 0, bottom: 0,
              width: 10,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, FridgeColors.sideDepth],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fridge Wall Custom Painter ────────────────────────────────────────────────
// Draws the cool-white interior wall with subtle vertical ribbing
class _FridgeWallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base wall fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = FridgeColors.interiorWall,
    );

    // Subtle vertical ribbing lines (like real fridge interior)
    final ribPaint = Paint()
      ..color = FridgeColors.shelfGlass.withOpacity(0.25)
      ..strokeWidth = 0.5;

    for (double x = 20; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), ribPaint);
    }
  }

  @override
  bool shouldRepaint(_FridgeWallPainter old) => false;
}

// ── Light Strip at Top ────────────────────────────────────────────────────────
class _LightStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: FridgeColors.lightStrip,
        boxShadow: [
          BoxShadow(
            color: FridgeColors.lightGlow.withOpacity(0.9),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // LED strip dots
          for (int i = 0; i < 12; i++) ...[
            const SizedBox(width: 8),
            Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Fridge Shelf ──────────────────────────────────────────────────────────────
// Wraps each category with a glass shelf visual below and a label pill above
class _FridgeShelf extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final int? count;
  final Widget child;
  final bool isFirst;

  const _FridgeShelf({
    required this.label,
    required this.labelIcon,
    required this.child,
    this.count,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Shelf label row ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(14, isFirst ? 10 : 6, 14, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: FridgeColors.shelfLabelBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(labelIcon, size: 12, color: FridgeColors.shelfLabelText),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FridgeColors.shelfLabelText,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: FridgeColors.shelfLabelText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Shelf content area ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: child,
        ),

        // ── Glass shelf edge ──────────────────────────────────────────────
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(double.infinity, 14),
          painter: _ShelfEdgePainter(),
        ),
      ],
    );
  }
}

// ── Shelf Edge Painter ────────────────────────────────────────────────────────
// Draws the frosted glass shelf edge
class _ShelfEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Glass body
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 2, size.width, 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(glassRect, Paint()..color = FridgeColors.shelfGlass);

    // Highlight on top edge
    canvas.drawLine(
      const Offset(0, 2),
      Offset(size.width, 2),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1.2,
    );

    // Shadow under shelf
    canvas.drawLine(
      Offset(4, 12),
      Offset(size.width - 4, 12),
      Paint()
        ..color = FridgeColors.shelfShadow
        ..strokeWidth = 2,
    );

    // Left and right bracket dots
    for (final x in [8.0, size.width - 8]) {
      canvas.drawCircle(
        Offset(x, 7),
        3,
        Paint()..color = FridgeColors.shelfEdge,
      );
    }
  }

  @override
  bool shouldRepaint(_ShelfEdgePainter old) => false;
}

// ── Status Shelf Content ──────────────────────────────────────────────────────
class _StatusShelfContent extends StatelessWidget {
  final int dangerCount;
  final int spoiledCount;
  final int goodCount;
  final int total;

  const _StatusShelfContent({
    required this.dangerCount,
    required this.spoiledCount,
    required this.goodCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _StatusCard(count: goodCount,    label: 'Good',    bg: AppColors.goodBg,    textColor: AppColors.goodText),
          const SizedBox(width: 8),
          _StatusCard(count: dangerCount,  label: 'Danger',  bg: AppColors.dangerBg,  textColor: AppColors.dangerText),
          const SizedBox(width: 8),
          _StatusCard(count: spoiledCount, label: 'Spoiled', bg: AppColors.spoiledBg, textColor: AppColors.spoiledText),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color textColor;

  const _StatusCard({required this.count, required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.15), width: 0.5),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

// ── Category Shelf Content ────────────────────────────────────────────────────
class _CategoryShelfContent extends StatelessWidget {
  final List<PredictionItem> items;
  final void Function(PredictionItem) onTap;

  const _CategoryShelfContent({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FridgeItemCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}

// ── Fridge Item Card ──────────────────────────────────────────────────────────
class _FridgeItemCard extends StatelessWidget {
  final PredictionItem item;
  final VoidCallback onTap;

  const _FridgeItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FridgeColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FridgeColors.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FridgeColors.interiorWall,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Stack(
                  children: [
                    // Status dot
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: item.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Icon
                    Center(
                      child: Icon(item.icon, size: 32, color: AppColors.medium.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
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
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

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
                    Text(item.type, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                  ],
                ),
              ),
              StatusBadge(label: item.statusLabel, bg: item.badgeBg, textColor: item.badgeText),
            ],
          ),

          const SizedBox(height: 20),

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

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                // _InfoRow(label: 'Previous Temp', value: '${item.oldTemp}°C'),
                // const SizedBox(height: 10),
                _InfoRow(label: 'Current Temp',  value: '${item.newTemp}°C'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Humidity',      value: '${item.humidity}%'),
                // const SizedBox(height: 10),
                // _InfoRow(label: 'Initial Life',  value: '${item.initialLife}h'),
                // const SizedBox(height: 10),
                // _InfoRow(label: 'Time Interval', value: '${item.timeBeforeTimeInBetween}h'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Life Remaining', value: '${item.lifeRemaining}h'),
                if (item.oldDecay != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Decay Rate', value: item.oldDecay!.toStringAsFixed(4)),
                ],
                if (item.spikeDamage != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Spike Damage', value: item.spikeDamage!.toStringAsFixed(4)),
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
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }
}