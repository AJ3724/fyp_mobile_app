import 'package:flutter/material.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top hero banner ─────────────────────────────────────────────
              _HeroBanner(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // ── App identity ──────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              size: 26, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'FreshGuard',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Smart fridge · zero waste',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Stat row ──────────────────────────────────────────────
                    Row(
                      children: const [
                        _StatCard(number: '24', label: 'Items tracked', icon: Icons.kitchen_rounded),
                        SizedBox(width: 10),
                        _StatCard(number: '3', label: 'Active alerts', icon: Icons.notifications_rounded),
                        SizedBox(width: 10),
                        _StatCard(number: '8', label: 'Recipes ready', icon: Icons.restaurant_menu_rounded),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Quick status ──────────────────────────────────────────
                    const _SectionLabel('Fridge at a glance'),
                    const SizedBox(height: 12),
                    _QuickStatusRow(),

                    const SizedBox(height: 24),

                    // ── CTA buttons ───────────────────────────────────────────
                    const _SectionLabel('Get started'),
                    const SizedBox(height: 12),

                    _ActionTile(
                      icon: Icons.kitchen_rounded,
                      title: 'View my fridge',
                      subtitle: 'Check all items & freshness levels',
                      color: AppColors.primary,
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.notifications_rounded,
                      title: 'Check alerts',
                      subtitle: '3 items need your attention',
                      color: AppColors.dangerColor,
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Today\'s recipes',
                      subtitle: 'AI-curated from your fridge',
                      color: AppColors.medium,
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),

                    // ── Footer tag ────────────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 24, height: 0.8, color: AppColors.divider),
                          const SizedBox(width: 10),
                          const Text(
                            'Automated · AI-powered · Real-time',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 24, height: 0.8, color: AppColors.divider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.medium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: 40,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Icons row
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeroIcon(icon: Icons.ac_unit_rounded, opacity: 0.5),
                const SizedBox(width: 20),
                _HeroIcon(icon: Icons.eco_rounded, opacity: 0.8, size: 44),
                const SizedBox(width: 20),
                _HeroIcon(icon: Icons.local_dining_rounded, opacity: 0.5),
              ],
            ),
          ),
          // Bottom label
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FRESHGUARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final double opacity;
  final double size;
  const _HeroIcon({required this.icon, required this.opacity, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: Colors.white.withOpacity(opacity));
  }
}

// ── Quick Status Row ──────────────────────────────────────────────────────────
class _QuickStatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: const [
          _StatusDot(label: '18 Good', color: AppColors.goodColor, bg: AppColors.goodBg),
          _StatusDivider(),
          _StatusDot(label: '3 Danger', color: AppColors.dangerColor, bg: AppColors.dangerBg),
          _StatusDivider(),
          _StatusDot(label: '3 Spoiled', color: AppColors.spoiledColor, bg: AppColors.spoiledBg),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusDot({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 0.8, height: 32, color: AppColors.divider);
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSub)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  const _StatCard(
      {required this.number, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.medium),
            const SizedBox(height: 6),
            Text(number,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSub),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}