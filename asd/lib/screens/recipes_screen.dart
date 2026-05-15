import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class RecommendedRecipe {
  final String dishName;
  final String category;
  final List<String> matchedIngredients;
  final double cosineScore;
  final double urgencyScore;
  final double finalScore;
  final String matchPct;

  const RecommendedRecipe({
    required this.dishName,
    required this.category,
    required this.matchedIngredients,
    required this.cosineScore,
    required this.urgencyScore,
    required this.finalScore,
    required this.matchPct,
  });

  factory RecommendedRecipe.fromJson(Map<String, dynamic> json) {
    return RecommendedRecipe(
      dishName          : json['dish_name']   ?? '',
      category          : json['category']    ?? '',
      matchedIngredients: List<String>.from(json['matched_ingredients'] ?? []),
      cosineScore       : double.parse(json['cosine_score'].toString()),
      urgencyScore      : double.parse(json['urgency_score'].toString()),
      finalScore        : double.parse(json['final_score'].toString()),
      matchPct          : json['match_pct']   ?? '',
    );
  }

  // Map category to icons
  IconData get icon1 {
    switch (category.toLowerCase()) {
      case 'main dish': return Icons.restaurant_rounded;
      case 'side dish': return Icons.grass_rounded;
      case 'soup':      return Icons.soup_kitchen_rounded;
      default:          return Icons.local_dining_rounded;
    }
  }

  IconData get icon2 {
    switch (category.toLowerCase()) {
      case 'main dish': return Icons.local_fire_department_rounded;
      case 'side dish': return Icons.eco_rounded;
      case 'soup':      return Icons.water_drop_rounded;
      default:          return Icons.grain_rounded;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<RecommendedRecipe> _recipes = [];
  bool _loading = true;
  String? _error;

  String get _apiUrl => kIsWeb
      ? 'http://localhost/freshguard/get_recipes.php'
      : 'http://10.0.2.2/freshguard/get_recipes.php';

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15)); // longer timeout for Python
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _recipes = data.map((j) => RecommendedRecipe.fromJson(j)).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.pale, size: 20),
                const SizedBox(width: 4),
                const Text('Based on your fridge',
                    style: TextStyle(fontSize: 11, color: AppColors.textSub)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _fetchRecipes,
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textSub),
                ),
                const SizedBox(width: 4),
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
              ? _ErrorView(message: _error!, onRetry: _fetchRecipes)
              : _recipes.isEmpty
                  ? const Center(
                      child: Text('No recipes match your fridge right now.',
                          style: TextStyle(color: AppColors.textSub)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.dangerColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recipes are ranked by urgency — items expiring soon are prioritised.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SectionLabel('Recommended for you'),
                        ..._recipes.map((recipe) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RecipeCard(recipe: recipe),
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

// ── Recipe Card ───────────────────────────────────────────────────────────────
class _RecipeCard extends StatelessWidget {
  final RecommendedRecipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Container(
            height: 80,
            color: const Color(0xFFD6E4EC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(recipe.icon1, size: 32, color: AppColors.primary),
                const SizedBox(width: 16),
                Icon(recipe.icon2, size: 32, color: AppColors.medium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + category
                Row(
                  children: [
                    Expanded(
                      child: Text(recipe.dishName,
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(recipe.category,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSub)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Match bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ingredient match',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub)),
                    Text(recipe.matchPct,
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 6),
                FreshnessBar(
                  fraction: double.tryParse(
                      recipe.matchPct.replaceAll('%', '')) != null
                      ? double.parse(recipe.matchPct.replaceAll('%', '')) / 100
                      : 0.0,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                // Ingredient pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: recipe.matchedIngredients
                      .map((ing) => _IngredientPill(name: ing))
                      .toList(),
                ),
                const SizedBox(height: 6),
                // Score info
                Text(
                  'Score: ${recipe.finalScore.toStringAsFixed(2)}  '
                  '(cosine ${recipe.cosineScore} × urgency ${recipe.urgencyScore})',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('View Recipe',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

class _IngredientPill extends StatelessWidget {
  final String name;
  const _IngredientPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(20)),
      child: Text(name, style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
    );
  }
}