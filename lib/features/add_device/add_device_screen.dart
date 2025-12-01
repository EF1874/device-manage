import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/models/category.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/category_picker.dart';
import 'widgets/platform_picker.dart';

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
  
  Category? _selectedCategory;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;
  bool _isLoading = false;
  
  String? _selectedPlatform;

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
      
      if (PlatformPicker.platforms.any((p) => p['name'] == d.platform)) {
        _selectedPlatform = d.platform;
      } else {
        _selectedPlatform = '其它';
        _customPlatformController.text = d.platform;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customPlatformController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final platform = _selectedPlatform == '其它' 
          ? _customPlatformController.text 
          : _selectedPlatform;

      final device = widget.device ?? Device();
      device
        ..name = _nameController.text
        ..price = double.parse(_priceController.text)
        ..purchaseDate = _purchaseDate
        ..platform = platform ?? ''
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..category.value = _selectedCategory;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(BuildContext context, {
    bool isWarranty = false,
    bool isBackup = false,
    bool isScrap = false,
  }) async {
    final initialDate = isWarranty
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
        if (isWarranty) {
          _warrantyDate = picked;
        } else if (isBackup) {
          _backupDate = picked;
        } else if (isScrap) {
          _scrapDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isEditing = widget.device != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑设备' : '添加设备')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameController,
              label: '物品名称',
              validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            CategoryPicker(
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: '价格',
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PlatformPicker(
                    selectedPlatform: _selectedPlatform,
                    onPlatformSelected: (p) => setState(() => _selectedPlatform = p),
                  ),
                ),
              ],
            ),
            if (_selectedPlatform == '其它') ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _customPlatformController,
                label: '请输入平台名称',
                validator: (v) => v?.isEmpty == true ? '请输入平台名称' : null,
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '购买日期',
                  border: OutlineInputBorder(),
                ),
                child: Text(dateFormat.format(_purchaseDate)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context, isWarranty: true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '保修截止日期 (可选)',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _warrantyDate != null ? dateFormat.format(_warrantyDate!) : '未设置',
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
                  _backupDate != null ? dateFormat.format(_backupDate!) : '未设置',
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
                ),
              ),
            ),
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
