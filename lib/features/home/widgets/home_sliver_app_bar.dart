import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/config/platform_config.dart';
import '../../../core/theme/theme_provider.dart';

class HomeSliverAppBar extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isGridView;
  final bool showExpiringList;
  final String sortField;
  final bool isAscending;
  final String? selectedPlatformFilter;

  final ValueChanged<bool> onGridViewChanged;
  final ValueChanged<bool> onShowExpiringChanged;
  final ValueChanged<String> onSortFieldChanged;
  final ValueChanged<bool> onSortOrderChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onAddDevice;

  const HomeSliverAppBar({
    super.key,
    required this.searchController,
    required this.isGridView,
    required this.showExpiringList,
    required this.sortField,
    required this.isAscending,
    required this.selectedPlatformFilter,
    required this.onGridViewChanged,
    required this.onShowExpiringChanged,
    required this.onSortFieldChanged,
    required this.onSortOrderChanged,
    required this.onPlatformFilterChanged,
    required this.onSearchChanged,
    required this.onAddDevice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: false, // Changed to false to keep it persistent
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Ensure opaque
      surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 130,
      title: Row(
        children: [
          const Spacer(),
          // Timeline icon removed as it is now in bottom bar
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: isGridView ? '列表视图' : '网格视图',
            onPressed: () => onGridViewChanged(!isGridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            itemBuilder: (context) {
              const double itemHeight = 36.0;
              final textStyle = Theme.of(context).textTheme.bodyMedium;
              return [
                PopupMenuItem(
                  value: 'theme',
                  height: itemHeight,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_6, size: 18),
                      const SizedBox(width: 8),
                      Text('切换主题', style: textStyle),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'toggle_expiring',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        showExpiringList
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showExpiringList ? '隐藏到期列表' : '显示到期列表',
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'platform_filter',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 18,
                        color: selectedPlatformFilter != null
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedPlatformFilter == null
                            ? '平台筛选'
                            : '平台: $selectedPlatformFilter',
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                // Sort Fields
                // Sort Fields
                PopupMenuItem(
                  value: 'field_date',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: sortField == 'date'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('购买日期', style: textStyle),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'field_price',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 18,
                        color: sortField == 'price'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('价格', style: textStyle),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'field_expiry',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: sortField == 'expiry'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('到期/报废时间', style: textStyle),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                // Sort Order
                PopupMenuItem(
                  value: 'order_desc',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: !isAscending
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('倒序', style: textStyle),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'order_asc',
                  height: itemHeight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: isAscending
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('顺序', style: textStyle),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (v) {
              if (v == 'theme') {
                _showThemeDialog(context, ref);
              } else if (v == 'toggle_expiring') {
                onShowExpiringChanged(!showExpiringList);
              } else if (v == 'platform_filter') {
                _showPlatformFilterDialog(context);
              } else if (v.startsWith('field_')) {
                onSortFieldChanged(v.substring(6));
              } else if (v == 'order_asc') {
                onSortOrderChanged(true);
              } else if (v == 'order_desc') {
                onSortOrderChanged(false);
              }
            },
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppTextField(
            controller: searchController,
            label: '搜索物品...',
            onChanged: (_) => onSearchChanged(),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeProvider);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('亮色模式'),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('暗色模式'),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPlatformFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Text(
                    '选择平台',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text('全部平台'),
                        leading: selectedPlatformFilter == null
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const SizedBox(width: 20),
                        onTap: () {
                          onPlatformFilterChanged(null);
                          Navigator.pop(context);
                        },
                      ),
                      ...PlatformConfig.shoppingPlatforms.map((p) {
                        final isSelected = selectedPlatformFilter == p.name;
                        return ListTile(
                          dense: true,
                          leading: Icon(p.icon, size: 20, color: p.color),
                          title: Text(p.name),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            onPlatformFilterChanged(p.name);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
