import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../providers/diet_provider.dart';
import '../widgets/custom_button.dart';
import '../data/exercise_food_library.dart';

class S13MealDetailScreen extends StatefulWidget {
  final Meal? meal;

  const S13MealDetailScreen({Key? key, this.meal}) : super(key: key);

  @override
  State<S13MealDetailScreen> createState() => _S13MealDetailScreenState();
}

class _S13MealDetailScreenState extends State<S13MealDetailScreen> {
  final Map<String, int> _quantities = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _searchKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<FoodLibraryItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        _showOverlay();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _hideOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      _overlayEntry?.markNeedsBuild();
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = ExerciseFoodLibrary.foodLibrary.where((e) {
        return e.name.toLowerCase().contains(lowerQuery);
      }).take(8).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    final RenderBox? renderBox = _searchKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 44);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: _searchResults.isEmpty 
                  ? const SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1, 
                          thickness: 1, 
                          color: Color(0xFF222222),
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return InkWell(
                            onTap: () {
                              _addFood(item);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: AppTextStyles.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.caloriesPer100g} kcal/100g',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _addFood(FoodLibraryItem item) {
    if (widget.meal == null) return;
    
    final newFood = FoodItem(
      name: item.name,
      calories: item.caloriesPer100g.round(),
      proteinG: item.proteinPer100g,
      carbsG: item.carbsPer100g,
      fatsG: item.fatsPer100g,
      quantityG: 100, // Starts at 100g
    );
    
    context.read<DietProvider>().addCustomFoodItem(widget.meal!.name, newFood);
    
    setState(() {
      _quantities[newFood.name] = 100;
      _searchResults.clear();
    });
    
    _searchController.clear();
    _searchFocus.unfocus();
    _hideOverlay();
  }

  void _confirmDelete(FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Delete Food?",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFFF0F0F0),
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${item.name} from this meal?",
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF888888),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<DietProvider>().removeCustomFoodItem(widget.meal!.name, item);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF888888)),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meal == null) {
      return const Scaffold(body: Center(child: Text('Error: No meal data')));
    }

    final dietProvider = Provider.of<DietProvider>(context);
    final currentPlan = dietProvider.currentPlan;
    Meal? currentMeal = currentPlan?.meals.firstWhere(
      (m) => m.name == widget.meal!.name,
      orElse: () => widget.meal!,
    );
    
    if (currentMeal == null) currentMeal = widget.meal!;

    // Ensure all items have a quantity entry
    for (var item in currentMeal.items) {
      if (!_quantities.containsKey(item.name)) {
        _quantities[item.name] = item.quantityG != null ? item.quantityG!.round() : 1;
      }
    }
    
    int liveTotalCalories = 0;
    for (var item in currentMeal.items) {
      bool isNewItem = item.quantityG != null;
      int q = _quantities[item.name] ?? (isNewItem ? 100 : 1);
      int displayCals = isNewItem 
          ? (item.calories * q / 100).round()
          : item.calories * q;
      liveTotalCalories += displayCals;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MEAL DETAIL', style: AppTextStyles.labelAllcaps),
                    const SizedBox(height: 8),
                    Text(currentMeal.name, style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text('$liveTotalCalories kcal', style: AppTextStyles.dataMedium.copyWith(color: AppColors.primaryAccent)),
                    const SizedBox(height: 24),
                    
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        key: _searchKey,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.secondaryText, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onChanged: _onSearchChanged,
                                style: AppTextStyles.bodyMedium,
                                decoration: const InputDecoration(
                                  hintText: 'Search foods',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    ...currentMeal.items.map((item) {
                      bool isConsumed = dietProvider.isItemConsumed(currentMeal!.name, item.name);
                      bool isNewItem = item.quantityG != null;
                      int quantity = _quantities[item.name] ?? (isNewItem ? 100 : 1);
                      int displayCals = isNewItem 
                          ? (item.calories * quantity / 100).round()
                          : item.calories * quantity;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isConsumed ? AppColors.strongAccent : AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    dietProvider.toggleItem(currentMeal!.name, item.name, !isConsumed);
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isConsumed ? AppColors.strongAccent : AppColors.border),
                                      color: isConsumed ? AppColors.strongAccent : Colors.transparent,
                                    ),
                                    child: isConsumed ? const Icon(Icons.check, size: 16, color: AppColors.background) : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name.toUpperCase(), style: AppTextStyles.labelLarge),
                                      const SizedBox(height: 4),
                                      Text('$displayCals kcal', style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFF888888), size: 20),
                                  onPressed: () => _confirmDelete(item),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Spacer(),
                                _buildStepperButton(Icons.remove, () {
                                  if (isNewItem) {
                                    if (quantity > 10) {
                                      setState(() => _quantities[item.name] = quantity - 10);
                                      dietProvider.updateCustomFoodQuantity(currentMeal!.name, item, (quantity - 10).toDouble());
                                    }
                                  } else {
                                    if (quantity > 1) {
                                      setState(() => _quantities[item.name] = quantity - 1);
                                    }
                                  }
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(isNewItem ? '${quantity}g' : '$quantity', style: AppTextStyles.dataMedium),
                                ),
                                _buildStepperButton(Icons.add, () {
                                  if (isNewItem) {
                                    setState(() => _quantities[item.name] = quantity + 10);
                                    dietProvider.updateCustomFoodQuantity(currentMeal!.name, item, (quantity + 10).toDouble());
                                  } else {
                                    setState(() => _quantities[item.name] = quantity + 1);
                                  }
                                }),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                text: "DONE",
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryText, size: 20),
      ),
    );
  }
}

