import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/custom_button.dart';
import '../providers/workout_provider.dart';
import '../data/exercise_food_library.dart';

class S08WorkoutDetailScreen extends StatefulWidget {
  final WorkoutDay? workoutDay;

  const S08WorkoutDetailScreen({Key? key, this.workoutDay}) : super(key: key);

  @override
  State<S08WorkoutDetailScreen> createState() => _S08WorkoutDetailScreenState();
}

class _S08WorkoutDetailScreenState extends State<S08WorkoutDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _searchKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<ExerciseLibraryItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        _showOverlay();
      } else {
        // slight delay to allow tap on dropdown
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
      _searchResults = ExerciseFoodLibrary.exerciseLibrary.where((e) {
        return e.name.toLowerCase().contains(lowerQuery) || 
               e.targetedMuscle.toLowerCase().contains(lowerQuery);
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
                              _addExercise(item);
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
                                    item.targetedMuscle,
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

  void _addExercise(ExerciseLibraryItem item) {
    if (widget.workoutDay == null) return;
    
    final newExercise = Exercise(
      name: item.name,
      targetedMuscle: item.targetedMuscle,
      sets: const [
        ExerciseSet(reps: 10, weight: 0.0),
        ExerciseSet(reps: 10, weight: 0.0),
        ExerciseSet(reps: 10, weight: 0.0),
      ],
    );
    
    context.read<WorkoutProvider>().addCustomExercise(widget.workoutDay!, newExercise);
    
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchResults.clear());
    _hideOverlay();
  }

  void _confirmDelete(Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Delete Exercise?",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFFF0F0F0),
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${exercise.name} from today's workout?",
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
              context.read<WorkoutProvider>().removeCustomExercise(widget.workoutDay!, exercise);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF888888)),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  void _onStartWorkout(WorkoutDay day) {
    final todayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][DateTime.now().weekday - 1];
    
    if (day.dayName != todayName) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            "Heads Up",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFFF0F0F0),
            ),
          ),
          content: Text(
            "You're about to start ${day.dayName}'s workout, but today is $todayName. We recommend following your plan in order for the best results. Are you sure you want to continue?",
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
              child: const Text("Go Back"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/workout/active', extra: day);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryText),
              child: const Text("Yes, I Know"),
            ),
          ],
        ),
      );
    } else {
      context.push('/workout/active', extra: day);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workoutDay == null) {
      return const Scaffold(body: Center(child: Text('Error: No workout data')));
    }
    
    // Get the updated workout day from provider
    final workoutProvider = context.watch<WorkoutProvider>();
    final currentPlan = workoutProvider.currentPlan;
    WorkoutDay? currentDay = currentPlan?.days.firstWhere(
      (d) => d.dayName == widget.workoutDay!.dayName,
      orElse: () => widget.workoutDay!,
    );
    
    if (currentDay == null) currentDay = widget.workoutDay!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/workout');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: () => context.go('/workout'),
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
                    Text(currentDay.dayName.toUpperCase(), style: AppTextStyles.labelAllcaps),
                    const SizedBox(height: 8),
                    Text(currentDay.workoutName, style: AppTextStyles.h2),
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
                                  hintText: 'Search exercises',
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
                    
                    ...currentDay.exercises.map((exercise) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(exercise.name.toUpperCase(), style: AppTextStyles.labelLarge),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFF888888), size: 20),
                                  onPressed: () => _confirmDelete(exercise),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('SET', style: AppTextStyles.labelAllcaps)),
                                Expanded(child: Text('REPS', style: AppTextStyles.labelAllcaps, textAlign: TextAlign.center)),
                                Expanded(child: Text('WEIGHT', style: AppTextStyles.labelAllcaps, textAlign: TextAlign.right)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...exercise.sets.asMap().entries.map((entry) {
                              int idx = entry.key;
                              ExerciseSet set = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('${idx + 1}', style: AppTextStyles.dataSmall)),
                                    Expanded(child: Text('${set.reps}', style: AppTextStyles.dataSmall, textAlign: TextAlign.center)),
                                    Expanded(child: Text('${set.weight} kg', style: AppTextStyles.dataSmall, textAlign: TextAlign.right)),
                                  ],
                                ),
                              );
                            }).toList(),
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
                text: "START WORKOUT",
                onPressed: () => _onStartWorkout(currentDay!),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
