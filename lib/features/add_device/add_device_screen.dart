import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/category_repository.dart';

import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/models/category.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/category_picker.dart';
import 'widgets/platform_picker.dart';
import '../../shared/config/category_config.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  final Device? device;

  const AddDeviceScreen({super.key, this.device});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _customPlatformController = TextEditingController();
  final _customCategoryController = TextEditingController();

  Category? _selectedCategory;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;
  bool _isLoading = false;

  String? _selectedPlatform;

  // Subscription State
  CycleType? _cycleType;
  bool _isAutoRenew = true;
  DateTime? _nextBillingDate;
  int _reminderDays = 1;
  bool _hasReminder = false;

  bool get _isSubscription =>
      CategoryConfig.getMajorCategory(_selectedCategory?.name) == '虚拟订阅';

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      _nameController.text = d.name;
      _priceController.text = d.price.toString();
      _purchaseDate = d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;

      _selectedPlatform = d.platform;

      _cycleType = d.cycleType;
      _isAutoRenew = d.isAutoRenew;
      _nextBillingDate = d.nextBillingDate;
      _reminderDays = d.reminderDays;
      _hasReminder = d.hasReminder;
    }
  }

  void _calculateNextBilling() {
    if (_cycleType == null || _cycleType == CycleType.oneTime) return;

    DateTime next = _purchaseDate;
    switch (_cycleType!) {
      case CycleType.weekly:
        next = next.add(const Duration(days: 7));
        break;
      case CycleType.monthly:
        int newMonth = next.month + 1;
        int newYear = next.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        int day = next.day;
        if (day > daysInNewMonth) day = daysInNewMonth;
        next = DateTime(newYear, newMonth, day, next.hour, next.minute);
        break;
      case CycleType.yearly:
        int newYear = next.year + 1;
        int newMonth = next.month;
        int day = next.day;
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        if (day > daysInNewMonth) day = daysInNewMonth;
        next = DateTime(newYear, newMonth, day, next.hour, next.minute);
        break;
      case CycleType.oneTime:
        return;
    }
    setState(() {
      _nextBillingDate = next;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customPlatformController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final platform = _selectedPlatform == '其它'
          ? _customPlatformController.text
          : _selectedPlatform;

      var finalCategory = _selectedCategory;
      if (_selectedCategory?.name == '其它') {
        final customName = _customCategoryController.text.trim();
        if (customName.isNotEmpty) {
          final existing = await ref
              .read(categoryRepositoryProvider)
              .findCategoryByName(customName);
          if (existing != null) {
            finalCategory = existing;
          } else {
            final newCat = Category()
              ..name = customName
              ..iconPath = 'MdiIcons.tag'
              ..isDefault = false;

            final id = await ref
                .read(categoryRepositoryProvider)
                .addCategory(newCat);
            finalCategory = newCat..id = id;
          }
        } else {
          final existing = await ref
              .read(categoryRepositoryProvider)
              .findCategoryByName('其它');
          if (existing != null) {
            finalCategory = existing;
          } else {
            final newCat = Category()
              ..name = '其它'
              ..iconPath = 'MdiIcons.dotsHorizontal'
              ..isDefault = false;
            final id = await ref
                .read(categoryRepositoryProvider)
                .addCategory(newCat);
            finalCategory = newCat..id = id;
          }
        }
      }

      final device = widget.device ?? Device();
      device
        ..name = _nameController.text
        ..price = double.parse(_priceController.text)
        ..purchaseDate = _purchaseDate
        ..platform = platform ?? ''
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..category.value = finalCategory
        ..cycleType = _isSubscription ? _cycleType : null
        ..isAutoRenew = _isSubscription ? _isAutoRenew : true
        ..nextBillingDate = _isSubscription ? _nextBillingDate : null
        ..reminderDays = _isSubscription ? _reminderDays : 1
        ..hasReminder = _isSubscription ? _hasReminder : false;

      if (widget.device != null) {
        await ref.read(deviceRepositoryProvider).updateDevice(device);
      } else {
        await ref.read(deviceRepositoryProvider).addDevice(device);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.device != null ? '修改成功' : '添加成功')),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(
    BuildContext context, {
    bool isWarranty = false,
    bool isBackup = false,
    bool isScrap = false,
    bool isBilling = false,
  }) async {
    final initialDate = isBilling
        ? (_nextBillingDate ?? DateTime.now())
        : isWarranty
        ? (_warrantyDate ?? DateTime.now())
        : isBackup
        ? (_backupDate ?? DateTime.now())
        : isScrap
        ? (_scrapDate ?? DateTime.now())
        : _purchaseDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CH'),
    );

    if (picked != null) {
      setState(() {
        if (isBilling) {
          _nextBillingDate = picked;
        } else if (isWarranty) {
          _warrantyDate = picked;
        } else if (isBackup) {
          _backupDate = picked;
        } else if (isScrap) {
          _scrapDate = picked;
        } else {
          _purchaseDate = picked;
          if (_isSubscription) _calculateNextBilling();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isEditing = widget.device != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑物品' : '添加物品')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameController,
              label: '名称',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            CategoryPicker(
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) {
                setState(() {
                  _selectedCategory = c;
                  if (_isSubscription) {
                    if (_nextBillingDate == null) _calculateNextBilling();
                    // Default reminders on for subscriptions
                    _hasReminder = true;
                    _reminderDays = 1;
                  }
                });
              },
            ),
            if (_selectedCategory?.name == '其它') ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _customCategoryController,
                label: '请输入分类名称 (选填)',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: '价格',
                    labelStyle: TextStyle(color: Theme.of(context).hintColor),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PlatformPicker(
                    selectedPlatform: _selectedPlatform,
                    onPlatformSelected: (p) =>
                        setState(() => _selectedPlatform = p),
                  ),
                ),
              ],
            ),
            if (_selectedPlatform == '其它') ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _customPlatformController,
                label: '请输入平台名称',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                validator: (v) => v?.isEmpty == true ? '请输入平台名称' : null,
              ),
            ],
            const SizedBox(height: 16),

            // Start Date (Unified)
            InkWell(
              onTap: () => _pickDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '购买日期 / 开始日期',
                  border: OutlineInputBorder(),
                ),
                child: Text(dateFormat.format(_purchaseDate)),
              ),
            ),

            const SizedBox(height: 16),

            // CONDITIONAL FIELDS
            if (_isSubscription) ...[
              // Cycle Type UI - Cleaner InputDecorator Style
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: '周期类型',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CycleType>(
                    value: _cycleType,
                    hint: const Text('请选择周期'),
                    isExpanded: true,
                    isDense: true,
                    items: CycleType.values.map((e) {
                      String label;
                      switch (e) {
                        case CycleType.monthly:
                          label = '每月';
                          break;
                        case CycleType.yearly:
                          label = '每年';
                          break;
                        case CycleType.weekly:
                          label = '每周';
                          break;
                        case CycleType.oneTime:
                          label = '一次性';
                          break;
                      }
                      return DropdownMenuItem(value: e, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _cycleType = v;
                        _calculateNextBilling();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('自动续费'),
                value: _isAutoRenew,
                onChanged: (v) => setState(() {
                  _isAutoRenew = v;
                }),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: () => _pickDate(context, isBilling: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _isAutoRenew
                        ? '下次扣款日 (Next Billing)'
                        : '到期日 (Expiration)',
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    _nextBillingDate != null
                        ? dateFormat.format(_nextBillingDate!)
                        : '请选择或自动计算',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reminder UI - No Border, 1-10 Days
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey(
                    _isSubscription,
                  ), // Force rebuild state if toggled
                  initiallyExpanded: true,
                  title: const Text('提醒设置'),
                  tilePadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active_outlined),
                  trailing: Switch(
                    value: _hasReminder,
                    onChanged: (v) => setState(() => _hasReminder = v),
                  ),
                  children: [
                    if (_hasReminder)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: '提前提醒天数',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: _reminderDays,
                          items: List.generate(10, (index) => index + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d 天前'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _reminderDays = v ?? 1),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Standard Logic
              InkWell(
                onTap: () => _pickDate(context, isWarranty: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '保修截止日期 (可选)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _warrantyDate != null
                        ? dateFormat.format(_warrantyDate!)
                        : '未设置',
                    style: _warrantyDate != null
                        ? null
                        : TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(context, isBackup: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '备用日期 (可选)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _backupDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _backupDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _backupDate != null
                        ? dateFormat.format(_backupDate!)
                        : '未设置',
                    style: _backupDate != null
                        ? null
                        : TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickDate(context, isScrap: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '报废日期 (可选)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _scrapDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _scrapDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _scrapDate != null ? dateFormat.format(_scrapDate!) : '未设置',
                    style: _scrapDate != null
                        ? null
                        : TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            AppButton(
              text: '保存',
              onPressed: _saveDevice,
              isLoading: _isLoading,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
