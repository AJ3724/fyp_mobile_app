import 'package:flutter/material.dart';
import '../theme.dart';

// ── Fridge Status ─────────────────────────────────────────────────────────────
enum FridgeStatus { good, acceptable, danger, spoiled }

// ── Prediction Item (from DB) ─────────────────────────────────────────────────
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
      id:                      int.parse(json['id'].toString()),
      itemName:                json['item_name'] ?? '',
      type:                    json['type'] ?? '',
      oldTemp:                 int.parse(json['old_temp'].toString()),
      newTemp:                 int.parse(json['new_temp'].toString()),
      humidity:                int.parse(json['humidity'].toString()),
      initialLife:             int.parse(json['initial_life'].toString()),
      timeBeforeTimeInBetween: int.parse(json['time_before_time_in_between'].toString()),
      lifeRemaining:           int.parse(json['life_remaining'].toString()),
      status:                  json['status'] ?? '',
      itemNameVal:             json['item_name_val'] != null ? int.parse(json['item_name_val'].toString()) : null,
      typeVal:                 json['type_val'] != null ? int.parse(json['type_val'].toString()) : null,
      oldDecay:                json['old_decay'] != null ? double.parse(json['old_decay'].toString()) : null,
      spikeDamage:             json['spike_damage'] != null ? double.parse(json['spike_damage'].toString()) : null,
    );
  }

  // ── Derived helpers ────────────────────────────────────────────────────────
  double get freshnessFraction =>
      initialLife > 0 ? (lifeRemaining / initialLife).clamp(0.0, 1.0) : 0.0;

  FridgeStatus get fridgeStatus {
    switch (status.toLowerCase()) {
      case 'good':       return FridgeStatus.good;
      case 'acceptable': return FridgeStatus.acceptable;
      case 'danger':     return FridgeStatus.danger;
      case 'spoiled':    return FridgeStatus.spoiled;
      default:
        if (lifeRemaining <= 0)                        return FridgeStatus.spoiled;
        if (lifeRemaining / initialLife < 0.2)         return FridgeStatus.danger;
        if (lifeRemaining / initialLife < 0.5)         return FridgeStatus.acceptable;
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
      case 'vegetable':  return Icons.grass_rounded;
      case 'fruit':      return Icons.energy_savings_leaf_rounded;
      case 'dairy':      return Icons.water_drop_outlined;
      case 'meat':       return Icons.restaurant_rounded;
      case 'herb':       return Icons.eco_rounded;
      case 'grain':      return Icons.grain_rounded;
      case 'condiment':  return Icons.local_dining_rounded;
      case 'beverage':   return Icons.local_drink_rounded;
      default:           return Icons.kitchen_rounded;
    }
  }
}

// ── Recipe ────────────────────────────────────────────────────────────────────
class RecipeIngredient {
  final String name;
  final bool isExpiring;
  const RecipeIngredient(this.name, {this.isExpiring = false});
}

class Recipe {
  final String name;
  final String category;
  final double matchFraction;
  final List<RecipeIngredient> ingredients;
  final IconData icon1;
  final IconData icon2;

  const Recipe({
    required this.name,
    required this.category,
    required this.matchFraction,
    required this.ingredients,
    required this.icon1,
    required this.icon2,
  });

  int get matchPercent => (matchFraction * 100).round();
}

// ── Sample Data ───────────────────────────────────────────────────────────────
class SampleData {
  static final List<Recipe> recipes = [
    Recipe(
      name: 'Tabbouleh', category: 'Side Dish', matchFraction: 1.0,
      icon1: Icons.grass_rounded, icon2: Icons.eco_rounded,
      ingredients: [
        RecipeIngredient('Parsley', isExpiring: true),
        RecipeIngredient('Tomato',  isExpiring: true),
        RecipeIngredient('Bulgur'),
      ],
    ),
    Recipe(
      name: 'Shish Tawook', category: 'Main Dish', matchFraction: 0.8,
      icon1: Icons.restaurant_rounded, icon2: Icons.local_fire_department_rounded,
      ingredients: [
        RecipeIngredient('Chicken'),
        RecipeIngredient('Garlic'),
        RecipeIngredient('Lemon', isExpiring: true),
        RecipeIngredient('Yogurt'),
      ],
    ),
    Recipe(
      name: 'Fattoush', category: 'Side Dish', matchFraction: 0.66,
      icon1: Icons.eco_rounded, icon2: Icons.grain_rounded,
      ingredients: [
        RecipeIngredient('Tomato', isExpiring: true),
        RecipeIngredient('Lettuce'),
        RecipeIngredient('Pita Bread'),
      ],
    ),
  ];
}