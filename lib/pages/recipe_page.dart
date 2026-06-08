import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/recipe_service.dart';
import '../services/favorite_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';

class RecipePage extends StatefulWidget {
  final String? initialSearch;

  const RecipePage({super.key, this.initialSearch});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  List<Recipe> _results = [];
  List<Recipe> _favorites = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFavorites();
    if (widget.initialSearch != null) {
      _controller.text = widget.initialSearch!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) _loadFavorites();
    if (mounted) setState(() {});
  }

  void _loadFavorites() {
    _favorites = favoriteService.getAll();
    if (mounted) setState(() {});
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await recipeService.searchByIngredient(query);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('ຄົ້ນຫາສູດອາຫານອັດສະລິຍະ'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(c),
            _buildTabBar(c),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _controller,
        style: TextStyle(color: c.text),
        decoration: InputDecoration(
          hintText: 'ຕ.ຍ. ໄກ່, ໄຂ່, ໝາກເລັ່ນ',
          hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
          filled: true,
          fillColor: c.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search, color: c.accent, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: c.textSecondary, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                  splashRadius: 16,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: c.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: c.accent,
          unselectedLabelColor: c.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'ຜົນການຄົ້ນຫາ (${_results.length})'),
            Tab(text: 'ລາຍການໂປດ (${_favorites.length})'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppThemeColors c) {
    if (_tabController.index == 1) return _buildFavoritesTab(c);
    return _buildResultsTab(c);
  }

  Widget _buildResultsTab(AppThemeColors c) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: c.textSecondary),
              const SizedBox(height: 12),
              Text(
                'ການຄົ້ນຫາຫຼົ້ມເຫຼວ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    if (!_searched) {
      return _buildEmptyState(
        c,
        icon: Icons.restaurant,
        title: 'ມີຫຍັງຢູ່ໃນຕູ້ເຢັນຂອງທ່ານ?',
        subtitle: 'ພິມສ່ວນປະສົມດ້ານເທິງ ແລະ ກົດຄົ້ນຫາ\nເພື່ອຊອກຫາສູດອາຫານ.',
      );
    }
    if (_results.isEmpty) {
      return _buildEmptyState(
        c,
        icon: Icons.sentiment_dissatisfied,
        title: 'ບໍ່ພົບສູດອາຫານ',
        subtitle: 'ລອງປ່ຽນສ່ວນປະສົມອື່ນ\nຕ.ຍ. ໄກ່, ໄຂ່, ເຂົ້າ',
      );
    }
    return _buildRecipeGrid(c, _results);
  }

  Widget _buildFavoritesTab(AppThemeColors c) {
    if (_favorites.isEmpty) {
      return _buildEmptyState(
        c,
        icon: Icons.favorite_border,
        title: 'ຍັງບໍ່ມີລາຍການໂປດ',
        subtitle: 'ແຕະໄອຄອນຫົວໃຈໃນສູດອາຫານ\nເພື່ອບັນທຶກໄວ້ທີ່ນີ້.',
      );
    }
    return _buildRecipeGrid(c, _favorites);
  }

  Widget _buildEmptyState(
    AppThemeColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: c.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(AppThemeColors c, List<Recipe> recipes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GridView.builder(
        itemCount: recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => _RecipeCard(
          recipe: recipes[index],
          c: c,
          onRefresh: _loadFavorites,
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final AppThemeColors c;
  final VoidCallback onRefresh;

  const _RecipeCard({
    required this.recipe,
    required this.c,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = favoriteService.isFavorite(recipe.id);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RecipeDetailPage(recipeId: recipe.id, recipe: recipe),
          ),
        );
        onRefresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        await favoriteService.toggle(recipe);
                        onRefresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${recipe.estimatedCalories} kcal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.public, size: 12, color: c.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          recipe.areaLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (recipe.category != null)
                          Text(
                            recipe.category!,
                            style: TextStyle(fontSize: 10, color: c.accent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (recipe.thumbnail.isEmpty) {
      return Container(
        color: c.surface,
        child: Center(
          child: Icon(Icons.restaurant, size: 40, color: c.textSecondary),
        ),
      );
    }
    return Image.network(
      recipe.thumbnail,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: c.surface,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: c.accent,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: c.surface,
          child: Center(
            child: Icon(Icons.broken_image, size: 32, color: c.textSecondary),
          ),
        );
      },
    );
  }
}
