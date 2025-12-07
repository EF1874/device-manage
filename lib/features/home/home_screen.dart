import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/config/category_config.dart';
import '../../data/services/preferences_service.dart';
import '../add_device/add_device_screen.dart';
import '../navigation/navigation_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/device_list_item.dart';
import 'widgets/device_grid_item.dart';
import 'widgets/sticky_filter_delegate.dart';
import '../../shared/config/platform_config.dart';

final deviceListProvider = StreamProvider((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.watchAllDevices();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;
  String _sortBy = 'date_desc'; // date_desc, date_asc, price_desc, price_asc
  Offset _fabPosition = const Offset(0, 0); // Will be initialized in build
  bool _isFabInitialized = false;

  String? _selectedFilterCategory;
  String? _selectedPlatformFilter;

  @override
  void initState() {
    super.initState();
    // Initialize state from preferences
    final prefs = ref.read(preferencesServiceProvider);
    _isGridView = prefs.isGridView;
    _sortBy = prefs.sortBy;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Device> _processDevices(List<Device> devices) {
    var result = List<Device>.from(devices);

    // Filter by Name
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result
          .where((d) => d.name.toLowerCase().contains(query))
          .toList();
    }

    // Filter by Category
    if (_selectedFilterCategory != null) {
      result = result.where((d) {
        final major = CategoryConfig.getMajorCategory(d.category.value?.name);
        return major == _selectedFilterCategory;
      }).toList();
    }

    // Filter by Platform
    if (_selectedPlatformFilter != null) {
      result = result
          .where((d) => d.platform == _selectedPlatformFilter)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'date_desc':
        result.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case 'date_asc':
        result.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    return result;
  }

  // State
  bool _showExpiringList = true;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(deviceListProvider);
    final size = MediaQuery.of(context).size;

    // ... FAB Init ...
    if (!_isFabInitialized) {
      _fabPosition = Offset(size.width - 72, size.height - 160);
      _isFabInitialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                ref.read(bottomNavBarVisibleProvider.notifier).state = false;
              } else if (notification.direction == ScrollDirection.forward) {
                ref.read(bottomNavBarVisibleProvider.notifier).state = true;
              }
              return true;
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 130,
                  title: Row(
                    children: [
                      const Text('Canghe 物历'),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                        ),
                        tooltip: _isGridView ? '列表视图' : '网格视图',
                        onPressed: () {
                          setState(() => _isGridView = !_isGridView);
                          ref
                              .read(preferencesServiceProvider)
                              .setGridView(_isGridView);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu),
                        onSelected: (v) {
                          if (v == 'theme') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('主题切换暂未实现')),
                            );
                          } else if (v == 'toggle_expiring') {
                            setState(
                              () => _showExpiringList = !_showExpiringList,
                            );
                          } else if (v.startsWith('sort_')) {
                            final sortKey = v.substring(5);
                            setState(() => _sortBy = sortKey);
                            ref
                                .read(preferencesServiceProvider)
                                .setSortBy(sortKey);
                          } else if (v == 'platform_filter') {
                            _showPlatformFilterDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_expiring',
                            child: Row(
                              children: [
                                Icon(
                                  _showExpiringList
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(_showExpiringList ? '隐藏到期列表' : '显示到期列表'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'platform_filter',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 20,
                                  color: _selectedPlatformFilter != null
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedPlatformFilter == null
                                      ? '平台筛选'
                                      : '平台: $_selectedPlatformFilter',
                                ),
                              ],
                            ),
                          ),
                          // ... Themes & Sorts (keep existing) ...
                          const PopupMenuItem(
                            value: 'theme',
                            child: Row(
                              children: [
                                Icon(Icons.brightness_6, size: 20),
                                const SizedBox(width: 8),
                                Text('切换主题'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'sort_date_desc',
                            child: Text('购买日期 (新→旧)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_date_asc',
                            child: Text('购买日期 (旧→新)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_price_desc',
                            child: Text('价格 (高→低)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_price_asc',
                            child: Text('价格 (低→高)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: AppTextField(
                        controller: _searchController,
                        label: '搜索设备...',
                        onChanged: (_) => setState(() {}),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SummaryCard(devicesAsync: devicesAsync),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyFilterDelegate(
                    selectedCategory: _selectedFilterCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedFilterCategory = category);
                    },
                  ),
                ),
                devicesAsync.when(
                  data: (devices) {
                    final processed = _processDevices(devices);

                    if (processed.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('暂无设备')),
                      );
                    }

                    // Split logic
                    List<Device> expiring = [];
                    List<Device> normal = [];

                    if (_showExpiringList) {
                      final now = DateTime.now();
                      for (var d in processed) {
                        bool isExpiring = false;
                        // Check Sub + Reminder Logic
                        if (CategoryConfig.getMajorCategory(
                              d.category.value?.name,
                            ) ==
                            '虚拟订阅') {
                          if (d.nextBillingDate != null) {
                            int diff = d.nextBillingDate!
                                .difference(now)
                                .inDays;
                            // Logic:
                            // If AutoRenew: Remind if diff <= reminderDays (and >= 0)
                            // If Not AutoRenew: Remind if diff <= reminderDays (and >= 0)
                            // Note: If diff < 0 it is Expired. Do we show it? Maybe.
                            // User said "Expiring soon list".

                            // Let's use d.reminderDays (default 1).
                            // If reminder is OFF (hasReminder=false), maybe we don't show?
                            // User said "Check reminder method...".
                            // If hasReminder is false, we probably skip.

                            if (d.hasReminder &&
                                diff <= d.reminderDays &&
                                diff >= 0) {
                              isExpiring = true;
                            }
                          }
                        }

                        if (isExpiring) {
                          expiring.add(d);
                        } else {
                          normal.add(d);
                        }
                      }
                    } else {
                      normal = processed;
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          // Expiring Section
                          if (expiring.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8.0,
                                  left: 4,
                                ),
                                child: Text(
                                  '即将到期 / 续费',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            _isGridView
                                ? SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => DeviceGridItem(
                                        device: expiring[index],
                                      ),
                                      childCount: expiring.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.75,
                                        ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => DeviceListItem(
                                        device: expiring[index],
                                      ),
                                      childCount: expiring.length,
                                    ),
                                  ),
                            SliverToBoxAdapter(
                              child: Divider(
                                height: 32,
                                thickness: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5),
                              ),
                            ),
                          ],

                          // Normal Section
                          if (normal.isNotEmpty) ...[
                            _isGridView
                                ? SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) =>
                                          DeviceGridItem(device: normal[index]),
                                      childCount: normal.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.75,
                                        ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) =>
                                          DeviceListItem(device: normal[index]),
                                      childCount: normal.length,
                                    ),
                                  ),
                          ],

                          if (normal.isEmpty && expiring.isNotEmpty)
                            // Show nothing extra
                            const SliverToBoxAdapter(child: SizedBox.shrink()),
                        ],
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
          // Positoned FAB ...
          Positioned(
            left: _fabPosition.dx,

            top: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition += details.delta;
                  // Clamp position to screen bounds
                  double dx = _fabPosition.dx.clamp(0.0, size.width - 56);
                  double dy = _fabPosition.dy.clamp(0.0, size.height - 56);
                  _fabPosition = Offset(dx, dy);
                });
              },
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddDeviceScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlatformFilterDialog() {
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
                        leading: _selectedPlatformFilter == null
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const SizedBox(width: 20),
                        onTap: () {
                          setState(() => _selectedPlatformFilter = null);
                          Navigator.pop(context);
                        },
                      ),
                      ...PlatformConfig.shoppingPlatforms.map((p) {
                        final isSelected = _selectedPlatformFilter == p.name;
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
                            setState(() => _selectedPlatformFilter = p.name);
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
