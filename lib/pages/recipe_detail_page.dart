import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/recipe_service.dart';
import '../services/favorite_service.dart';
import '../models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;
  final Recipe recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    required this.recipe,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Recipe? _detailed;
  bool _loadingDetail = false;
  late bool _isFavorite;

  Recipe get r => _detailed ?? widget.recipe;

  @override
  void initState() {
    super.initState();
    _isFavorite = favoriteService.isFavorite(widget.recipeId);
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.recipe.instructions != null &&
        widget.recipe.ingredients != null) {
      _detailed = widget.recipe;
      return;
    }
    setState(() => _loadingDetail = true);
    final detail = await recipeService.getRecipeDetail(widget.recipeId);
    if (mounted) {
      setState(() {
        _detailed = detail;
        _loadingDetail = false;
      });
    }
  }

  Future<void> _toggleFav() async {
    await favoriteService.toggle(r);
    if (mounted) {
      setState(() => _isFavorite = favoriteService.isFavorite(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(c),
            SliverToBoxAdapter(child: _buildImage(c)),
            SliverToBoxAdapter(child: _buildInfo(c)),
            if (_loadingDetail)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: c.accent),
                  ),
                ),
              )
            else ...[
              if (r.ingredients != null)
                SliverToBoxAdapter(child: _buildIngredients(c)),
              if (r.instructions != null)
                SliverToBoxAdapter(child: _buildInstructions(c)),
              if (r.youtubeUrl != null && r.youtubeUrl!.isNotEmpty)
                SliverToBoxAdapter(child: _buildYoutubeButton(c)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppThemeColors c) {
    return SliverAppBar(
      backgroundColor: c.appBar,
      foregroundColor: c.accentTertiary,
      elevation: 0,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.redAccent : c.text,
          ),
          onPressed: _toggleFav,
          tooltip: 'ບັນທຶກໃນລາຍການໂປດ',
        ),
      ],
    );
  }

  Widget _buildImage(AppThemeColors c) {
    if (r.thumbnail.isEmpty) {
      return Container(
        height: 220,
        color: c.surface,
        child: Center(
          child: Icon(Icons.restaurant, size: 80, color: c.textSecondary),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Image.network(
        r.thumbnail,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 240,
          color: c.surface,
          child: Center(
            child: Icon(Icons.broken_image, size: 60, color: c.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.public, size: 14, color: c.accent),
              const SizedBox(width: 4),
              Text(r.areaLabel,
                  style: TextStyle(fontSize: 13, color: c.accent)),
              const SizedBox(width: 12),
              if (r.category != null) ...[
                Icon(Icons.category, size: 14, color: c.accent),
                const SizedBox(width: 4),
                Text(r.category!,
                    style: TextStyle(fontSize: 13, color: c.accent)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.local_fire_department,
                label: '${r.estimatedCalories} kcal',
                c: c,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients(AppThemeColors c) {
    final ings = r.ingredients!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_basket, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text('ສ່ວນປະສົມ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
              Text(' (${ings.length})',
                  style: TextStyle(
                      fontSize: 13, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...ings.map(
            (ing) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: c.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ing,
                        style: TextStyle(fontSize: 14, color: c.text)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Text('ວິທີເຮັດ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.instructions!,
            style: TextStyle(fontSize: 14, color: c.text, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubeButton(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () async {
            final uri = Uri.tryParse(r.youtubeUrl!);
            if (uri == null) return;
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } on MissingPluginException {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ບໍ່ສາມາດເປີດລິ້ງໄດ້. ລັນ "cd ios && pod install" ກ່ອນ.',
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.play_circle_fill, size: 20),
          label: const Text('ເບິ່ງໃນ YouTube'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppThemeColors c;

  const _Chip({
    required this.icon,
    required this.label,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: c.text)),
        ],
      ),
    );
  }
}
