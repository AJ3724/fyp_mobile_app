import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum ScanItemState {
  pendingExpiry,   // AI recognised, needs expiry confirmation
  unrecognized,    // AI couldn't identify; needs a name
  confirmed,       // User confirmed everything
  aiDefault,       // User skipped; AI applied a default expiry
}

class ScanItem {
  final String id;
  final String? detectedName;     // null when unrecognized
  final String type;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  ScanItemState state;
  DateTime? expiryDate;
  String? userProvidedName;
  final String? aiConfidence;     // e.g. "94%"
  final int? suggestedDays;       // AI default shelf life

  ScanItem({
    required this.id,
    this.detectedName,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.state,
    this.expiryDate,
    this.userProvidedName,
    this.aiConfidence,
    this.suggestedDays,
  });

  String get displayName =>
      userProvidedName ?? detectedName ?? 'Unknown item';
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE SCAN DATA
// ─────────────────────────────────────────────────────────────────────────────

List<ScanItem> buildSampleScanItems() => [
      ScanItem(
        id: '1',
        detectedName: 'Cherry Tomatoes',
        type: 'Vegetable',
        icon: Icons.grass_rounded,
        iconColor: const Color(0xFFE53935),
        iconBg: const Color(0xFFFFEAEA),
        state: ScanItemState.pendingExpiry,
        aiConfidence: '97%',
        suggestedDays: 7,
      ),
      ScanItem(
        id: '2',
        detectedName: null, // unrecognized
        type: 'Unknown',
        icon: Icons.help_outline_rounded,
        iconColor: AppColors.textMuted,
        iconBg: AppColors.surfaceAlt,
        state: ScanItemState.unrecognized,
        aiConfidence: null,
        suggestedDays: null,
      ),
      ScanItem(
        id: '3',
        detectedName: 'Greek Yogurt',
        type: 'Dairy',
        icon: Icons.water_drop_outlined,
        iconColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE3F2FD),
        state: ScanItemState.pendingExpiry,
        aiConfidence: '91%',
        suggestedDays: 14,
      ),
      ScanItem(
        id: '4',
        detectedName: 'Chicken Breast',
        type: 'Meat',
        icon: Icons.restaurant_rounded,
        iconColor: const Color(0xFF6D4C41),
        iconBg: const Color(0xFFFBE9E7),
        state: ScanItemState.pendingExpiry,
        aiConfidence: '88%',
        suggestedDays: 3,
      ),
      ScanItem(
        id: '5',
        detectedName: 'Fresh Parsley',
        type: 'Herb',
        icon: Icons.eco_rounded,
        iconColor: AppColors.medium,
        iconBg: AppColors.goodBg,
        state: ScanItemState.pendingExpiry,
        aiConfidence: '99%',
        suggestedDays: 5,
      ),
      ScanItem(
        id: '6',
        detectedName: null, // unrecognized
        type: 'Unknown',
        icon: Icons.help_outline_rounded,
        iconColor: AppColors.textMuted,
        iconBg: AppColors.surfaceAlt,
        state: ScanItemState.unrecognized,
        aiConfidence: null,
        suggestedDays: null,
      ),
      ScanItem(
        id: '7',
        detectedName: 'Orange Juice',
        type: 'Beverage',
        icon: Icons.local_drink_rounded,
        iconColor: const Color(0xFFE65100),
        iconBg: const Color(0xFFFFF3E0),
        state: ScanItemState.pendingExpiry,
        aiConfidence: '95%',
        suggestedDays: 10,
      ),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late List<ScanItem> _items;
  late AnimationController _headerPulse;
  late Animation<double> _pulseAnim;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _items = buildSampleScanItems();
    _headerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _headerPulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _headerPulse.dispose();
    super.dispose();
  }

  int get _pendingCount => _items
      .where((i) =>
          i.state == ScanItemState.pendingExpiry ||
          i.state == ScanItemState.unrecognized)
      .length;

  int get _confirmedCount => _items
      .where((i) =>
          i.state == ScanItemState.confirmed ||
          i.state == ScanItemState.aiDefault)
      .length;

  void _onItemConfirmed(ScanItem item) {
    setState(() {
      item.state = item.expiryDate != null
          ? ScanItemState.confirmed
          : ScanItemState.aiDefault;
      _checkAllDone();
    });
  }

  void _onAiDefault(ScanItem item) {
    setState(() {
      final days = item.suggestedDays ?? 7;
      item.expiryDate = DateTime.now().add(Duration(days: days));
      item.state = ScanItemState.aiDefault;
      _checkAllDone();
    });
  }

  void _onNameProvided(ScanItem item, String name) {
    setState(() {
      item.userProvidedName = name;
      item.state = ScanItemState.pendingExpiry;
    });
  }

  void _onExpirySet(ScanItem item, DateTime date) {
    setState(() {
      item.expiryDate = date;
      item.state = ScanItemState.confirmed;
      _checkAllDone();
    });
  }

  void _checkAllDone() {
    _allDone = _pendingCount == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scan Header ───────────────────────────────────────────────
            _ScanHeader(
              pulseAnim: _pulseAnim,
              totalItems: _items.length,
              confirmedCount: _confirmedCount,
              pendingCount: _pendingCount,
            ),

            // ── Progress bar ──────────────────────────────────────────────
            _ProgressBar(
              confirmed: _confirmedCount,
              total: _items.length,
            ),

            // ── Items list ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ScanItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    index: index,
                    onConfirmed: () => _onItemConfirmed(item),
                    onAiDefault: () => _onAiDefault(item),
                    onNameProvided: (name) => _onNameProvided(item, name),
                    onExpirySet: (date) => _onExpirySet(item, date),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bottom CTA ─────────────────────────────────────────────────────
      bottomNavigationBar: _BottomCta(
        allDone: _allDone,
        confirmedCount: _confirmedCount,
        total: _items.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ScanHeader extends StatelessWidget {
  final Animation<double> pulseAnim;
  final int totalItems;
  final int confirmedCount;
  final int pendingCount;

  const _ScanHeader({
    required this.pulseAnim,
    required this.totalItems,
    required this.confirmedCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A4A2A), Color(0xFF1A7A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Animated scan icon
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: pendingCount > 0 ? pulseAnim.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendingCount > 0
                      ? '$pendingCount item${pendingCount == 1 ? '' : 's'} need${pendingCount == 1 ? 's' : ''} your attention'
                      : 'All items confirmed — great job!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_rounded,
                    size: 12, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  '$confirmedCount / $totalItems',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int confirmed;
  final int total;
  const _ProgressBar({required this.confirmed, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? confirmed / total : 0.0;
    return Container(
      color: const Color(0xFF0A4A2A),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) => LinearProgressIndicator(
          value: value,
          minHeight: 4,
          backgroundColor: Colors.white.withOpacity(0.15),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6EE0A0)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN ITEM TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ScanItemTile extends StatefulWidget {
  final ScanItem item;
  final int index;
  final VoidCallback onConfirmed;
  final VoidCallback onAiDefault;
  final void Function(String) onNameProvided;
  final void Function(DateTime) onExpirySet;

  const _ScanItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onConfirmed,
    required this.onAiDefault,
    required this.onNameProvided,
    required this.onExpirySet,
  });

  @override
  State<_ScanItemTile> createState() => _ScanItemTileState();
}

class _ScanItemTileState extends State<_ScanItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;
  bool _expanded = true;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOutCubic,
    );

    // Already-done items start collapsed
    if (widget.item.state == ScanItemState.confirmed ||
        widget.item.state == ScanItemState.aiDefault) {
      _expanded = false;
      _expandCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _collapse() {
    setState(() => _expanded = false);
    _expandCtrl.reverse();
  }

  bool get _isDone =>
      widget.item.state == ScanItemState.confirmed ||
      widget.item.state == ScanItemState.aiDefault;

  Color get _borderColor {
    switch (widget.item.state) {
      case ScanItemState.unrecognized:
        return const Color(0xFFB87800);
      case ScanItemState.pendingExpiry:
        return AppColors.medium.withOpacity(0.4);
      case ScanItemState.confirmed:
        return AppColors.goodColor.withOpacity(0.5);
      case ScanItemState.aiDefault:
        return AppColors.textMuted.withOpacity(0.4);
    }
  }

  Color get _headerBg {
    switch (widget.item.state) {
      case ScanItemState.unrecognized:
        return const Color(0xFFFFF8E1);
      case ScanItemState.pendingExpiry:
        return Colors.white;
      case ScanItemState.confirmed:
        return AppColors.goodBg;
      case ScanItemState.aiDefault:
        return AppColors.surfaceAlt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _headerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Item Header Row ─────────────────────────────────────────
            GestureDetector(
              onTap: _isDone
                  ? () {
                      setState(() => _expanded = !_expanded);
                      _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: widget.item.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.item.icon,
                          size: 22, color: widget.item.iconColor),
                    ),
                    const SizedBox(width: 12),
                    // Name + type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.item.state == ScanItemState.unrecognized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.acceptBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFD4A853),
                                    width: 0.8),
                              ),
                              child: const Text(
                                '? Unrecognized item',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A5200),
                                ),
                              ),
                            )
                          else
                            Text(
                              widget.item.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isDone
                                    ? AppColors.textSub
                                    : AppColors.textPrimary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Row(children: [
                            Text(
                              widget.item.type,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                            if (widget.item.aiConfidence != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.goodBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${widget.item.aiConfidence} confidence',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.goodText,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    // Status badge
                    _StatusBadge(state: widget.item.state),
                  ],
                ),
              ),
            ),

            // ── Expandable Action Area ──────────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: AppColors.border,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: _buildActionArea(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    // ── Already done ────────────────────────────────────────────────────
    if (_isDone) {
      return _DoneArea(item: widget.item);
    }

    // ── Unrecognized: ask for name ───────────────────────────────────────
    if (widget.item.state == ScanItemState.unrecognized) {
      return _UnrecognizedArea(
        controller: _nameCtrl,
        onSubmit: (name) {
          if (name.trim().isEmpty) return;
          widget.onNameProvided(name.trim());
        },
      );
    }

    // ── Pending expiry ───────────────────────────────────────────────────
    return _ExpiryArea(
      item: widget.item,
      onSetExpiry: (date) {
        widget.onExpirySet(date);
        _collapse();
      },
      onAiDefault: () {
        widget.onAiDefault();
        _collapse();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION AREAS
// ─────────────────────────────────────────────────────────────────────────────

/// Area for unrecognized items — asks the user what it is
class _UnrecognizedArea extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;

  const _UnrecognizedArea(
      {required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI bubble
        _AiBubble(
          text:
              "I couldn't identify this item from the scan. Could you tell me what it is?",
          icon: Icons.smart_toy_rounded,
        ),
        const SizedBox(height: 12),
        // Text input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Feta Cheese, Leftover pasta…',
                    hintStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ),
                  onSubmitted: onSubmit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSubmit(controller.text),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onSubmit('Unknown item'),
          child: const Text(
            'Skip — mark as unknown',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}

/// Area for pending expiry items
class _ExpiryArea extends StatefulWidget {
  final ScanItem item;
  final void Function(DateTime) onSetExpiry;
  final VoidCallback onAiDefault;

  const _ExpiryArea({
    required this.item,
    required this.onSetExpiry,
    required this.onAiDefault,
  });

  @override
  State<_ExpiryArea> createState() => _ExpiryAreaState();
}

class _ExpiryAreaState extends State<_ExpiryArea> {
  int _selectedDays = -1; // -1 = none selected yet

  static const List<int> _quickDays = [3, 5, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final aiDays = widget.item.suggestedDays ?? 7;
    final aiExpiry = DateTime.now().add(Duration(days: aiDays));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI bubble
        _AiBubble(
          text: widget.item.detectedName != null
              ? 'I detected "${widget.item.detectedName}". Do you want to set an expiry date, or should I use my default of $aiDays days?'
              : 'Would you like to set an expiry date for this item?',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 12),

        // Quick-pick buttons
        const Text(
          'QUICK SELECT',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: _quickDays.map((d) {
            final isSelected = _selectedDays == d;
            final isAi = d == aiDays;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDays = d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isAi
                            ? AppColors.goodBg
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAi
                              ? AppColors.goodColor.withOpacity(0.5)
                              : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$d',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isAi
                                  ? AppColors.goodText
                                  : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'd',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textMuted,
                        ),
                      ),
                      if (isAi)
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.medium,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Action row
        Row(
          children: [
            // Custom date picker
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    widget.onSetExpiry(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.textSub),
                      SizedBox(width: 6),
                      Text(
                        'Pick date',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Confirm selection OR use AI default
            Expanded(
              flex: 2,
              child: _selectedDays > 0
                  ? GestureDetector(
                      onTap: () {
                        final date = DateTime.now()
                            .add(Duration(days: _selectedDays));
                        widget.onSetExpiry(date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Confirm',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: widget.onAiDefault,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.goodBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.goodColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 14, color: AppColors.medium),
                            const SizedBox(width: 6),
                            Text(
                              'Use AI default ($aiDays d)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.goodText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Collapsed area for confirmed items
class _DoneArea extends StatelessWidget {
  final ScanItem item;
  const _DoneArea({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAi = item.state == ScanItemState.aiDefault;
    final expiry = item.expiryDate;
    final daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays
        : 0;

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAi ? AppColors.surfaceAlt : AppColors.goodBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAi
                  ? AppColors.border
                  : AppColors.goodColor.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAi
                    ? Icons.auto_awesome_rounded
                    : Icons.check_circle_rounded,
                size: 14,
                color: isAi ? AppColors.textMuted : AppColors.goodColor,
              ),
              const SizedBox(width: 6),
              Text(
                isAi ? 'AI default applied' : 'Expiry confirmed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isAi ? AppColors.textSub : AppColors.goodText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (expiry != null)
          Text(
            'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ScanItemState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color bg, text;
    String label;

    switch (state) {
      case ScanItemState.unrecognized:
        icon = Icons.help_rounded;
        bg = AppColors.acceptBg;
        text = const Color(0xFF7A5200);
        label = 'ID needed';
        break;
      case ScanItemState.pendingExpiry:
        icon = Icons.schedule_rounded;
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        label = 'Expiry?';
        break;
      case ScanItemState.confirmed:
        icon = Icons.check_circle_rounded;
        bg = AppColors.goodBg;
        text = AppColors.goodText;
        label = 'Done';
        break;
      case ScanItemState.aiDefault:
        icon = Icons.auto_awesome_rounded;
        bg = AppColors.surfaceAlt;
        text = AppColors.textSub;
        label = 'AI set';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: text)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI SPEECH BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  const _AiBubble({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A4A2A), Color(0xFF1A7A44)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7F1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool allDone;
  final int confirmedCount;
  final int total;

  const _BottomCta({
    required this.allDone,
    required this.confirmedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allDone
                      ? 'All $total items are ready!'
                      : '$confirmedCount of $total items confirmed',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                Text(
                  allDone
                      ? 'Tap to add everything to your fridge'
                      : 'Review remaining items above',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: allDone ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allDone ? AppColors.primary : AppColors.border,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_to_photos_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Add to Fridge',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}