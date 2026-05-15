import 'package:flutter/material.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Hero illustration ────────────────────────────────────
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: const [
                    Flexible(child: Icon(Icons.ac_unit_rounded,     size: 38, color: AppColors.medium)),
                    SizedBox(width: 14),
                    Flexible(child: Icon(Icons.eco_rounded,          size: 38, color: AppColors.light)),
                    SizedBox(width: 14),
                    Flexible(child: Icon(Icons.local_dining_rounded, size: 38, color: AppColors.pale)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Logo + name ──────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.verified_user_rounded, size: 32, color: Colors.white),
              ),

              const SizedBox(height: 14),

              const Text(
                'FreshGuard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Smart fridge · zero waste',
                style: TextStyle(fontSize: 13, color: AppColors.textSub),
              ),

              const SizedBox(height: 28),

              // ── Stat pills ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _StatPill(number: '24', label: 'Items'),
                  SizedBox(width: 8),
                  _StatPill(number: '3',  label: 'Alerts'),
                  SizedBox(width: 8),
                  _StatPill(number: '8',  label: 'Recipes'),
                ],
              ),

              const SizedBox(height: 32),

              // ── CTA buttons ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Get Started', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Sign in', style: TextStyle(fontSize: 15)),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Automated · AI-powered · Real-time',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String number;
  final String label;
  const _StatPill({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(number, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          Text(label,  style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
        ],
      ),
    );
  }
}