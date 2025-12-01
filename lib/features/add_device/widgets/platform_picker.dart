import 'package:flutter/material.dart';

class PlatformPicker extends StatelessWidget {
  final String? selectedPlatform;
  final ValueChanged<String> onPlatformSelected;

  const PlatformPicker({
    super.key,
    this.selectedPlatform,
    required this.onPlatformSelected,
  });

  static const List<Map<String, dynamic>> platforms = [
    {'name': '京东', 'icon': Icons.shopping_bag, 'color': Colors.red},
    {'name': '淘宝', 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'name': '天猫', 'icon': Icons.store, 'color': Colors.redAccent},
    {'name': '拼多多', 'icon': Icons.group_work, 'color': Colors.red},
    {'name': '苏宁易购', 'icon': Icons.electrical_services, 'color': Colors.amber},
    {'name': '亚马逊', 'icon': Icons.language, 'color': Colors.blueGrey},
    {'name': '闲鱼', 'icon': Icons.recycling, 'color': Colors.yellow},
    {'name': '转转', 'icon': Icons.sync_alt, 'color': Colors.red},
    {'name': '线下实体店', 'icon': Icons.storefront, 'color': Colors.green},
    {'name': '其它', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedItem = platforms.firstWhere(
      (p) => p['name'] == selectedPlatform,
      orElse: () => {'name': '', 'icon': Icons.shopping_bag, 'color': Colors.grey},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPlatformSheet(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '购买平台',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: selectedPlatform != null && selectedPlatform!.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(selectedItem['icon'] as IconData, 
                           size: 20, 
                           color: selectedItem['color'] as Color),
                      const SizedBox(width: 8),
                      Text(selectedPlatform!),
                    ],
                  )
                : const Text('请选择平台', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _showPlatformSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择购买平台',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: platforms.map((platform) {
                final isSelected = selectedPlatform == platform['name'];
                return ChoiceChip(
                  label: Text(platform['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onPlatformSelected(platform['name'] as String);
                      Navigator.pop(ctx);
                    }
                  },
                  avatar: Icon(
                    platform['icon'] as IconData,
                    size: 18,
                    color: platform['color'] as Color,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
