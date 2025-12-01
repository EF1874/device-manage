import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../shared/config/category_config.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getAllCategories();
});

class CategoryPicker extends ConsumerWidget {
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;

  const CategoryPicker({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'phone_android': return Icons.phone_android;
      case 'computer': return Icons.computer;
      case 'tablet_mac': return Icons.tablet_mac;
      case 'headphones': return Icons.headphones;
      case 'camera_alt': return Icons.camera_alt;
      case 'videogame_asset': return Icons.videogame_asset;
      case 'kitchen': return Icons.kitchen;
      case 'home_mini': return Icons.home_mini;
      case 'watch': return Icons.watch;
      case 'piano': return Icons.piano;
      case 'directions_bike': return Icons.directions_bike;
      case 'menu_book': return Icons.menu_book;
      case 'devices_other': return Icons.devices_other;
      case 'local_convenience_store': return Icons.local_convenience_store;
      case 'print': return Icons.print;
      case 'checkroom': return Icons.checkroom;
      case 'face': return Icons.face;
      case 'child_care': return Icons.child_care;
      case 'restaurant': return Icons.restaurant;
      case 'chair': return Icons.chair;
      case 'directions_car': return Icons.directions_car;
      case 'cloud': return Icons.cloud;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = selectedCategory != null 
        ? CategoryConfig.getItem(selectedCategory!.name).color 
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showCategorySheet(context, ref),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '分类',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: selectedCategory != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconData(selectedCategory!.iconPath), 
                        size: 20,
                        color: selectedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(selectedCategory!.name),
                    ],
                  )
                : const Text('请选择分类', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final categoriesAsync = ref.watch(categoriesProvider);
          
          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择分类',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categories.map((category) {
                      final isSelected = selectedCategory?.id == category.id;
                      final itemConfig = CategoryConfig.getItem(category.name);
                      
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            onCategorySelected(category);
                            Navigator.pop(ctx);
                          }
                        },
                        avatar: Icon(
                          _getIconData(category.iconPath),
                          size: 18,
                          color: itemConfig.color,
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
