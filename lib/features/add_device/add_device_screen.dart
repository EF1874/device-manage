import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../data/models/category.dart';
import '../../data/models/device.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/widgets/app_button.dart';

import 'widgets/basic_info_section.dart';
import 'widgets/date_section.dart';
import 'widgets/subscription_section.dart';
import 'widgets/renew_dialog.dart';

part 'add_device_logic.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  final Device? device;
  const AddDeviceScreen({super.key, this.device});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  final _platformCtr = TextEditingController();
  final _catCtr = TextEditingController();
  final _firstPriceCtr = TextEditingController();
  final _totalAccumulatedPriceCtr = TextEditingController();

  Category? _selectedCategory;
  String? _selectedPlatform;
  String? _customIconPath;
  bool _isLoading = false;

  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;

  CycleType? _cycleType;
  bool _isAutoRenew = false;
  DateTime? _nextBillingDate;
  int _reminderDays = 1;
  bool _hasReminder = false;
  bool _discount = false;
  double _totalAccumulatedPrice = 0.0;

  DateTime? _originalNextBillingDate;
  bool _hasPendingRenewal = false;
  double _lastRenewPrice = 0.0;
  DateTime? _preRenewalNextBillingDate;
  double _baseAccumulatedPrice = 0.0;
  
  final ImagePicker _picker = ImagePicker();

  bool get _isSub =>
      CategoryConfig.getMajorCategory(_selectedCategory?.name) == '虚拟订阅';

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      _nameCtr.text = d.name;
      _priceCtr.text = d.price.toString();
      _purchaseDate = d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;
      _selectedPlatform = d.platform;
      _customIconPath = d.customIconPath;
      _cycleType = d.cycleType;
      _isAutoRenew = d.isAutoRenew;
      _nextBillingDate = d.nextBillingDate;
      _hasReminder = d.hasReminder;
      _firstPriceCtr.text = d.firstPeriodPrice?.toString() ?? '';
      _discount = d.firstPeriodPrice != null;
      _totalAccumulatedPrice = d.totalAccumulatedPrice;
      _totalAccumulatedPriceCtr.text = d.totalAccumulatedPrice % 1 == 0
          ? d.totalAccumulatedPrice.toInt().toString()
          : d.totalAccumulatedPrice.toString();
      _originalNextBillingDate = d.nextBillingDate;

      // Calculate base price from existing total
      double currentCost = d.firstPeriodPrice ?? d.price;
      _baseAccumulatedPrice = d.totalAccumulatedPrice - currentCost;
    } else {
      _baseAccumulatedPrice = 0.0;
    }

    _priceCtr.addListener(_updateTotalStr);
    _firstPriceCtr.addListener(_updateTotalStr);
    _totalAccumulatedPriceCtr.addListener(_updateBase);
  }

  // Helper to allow extension to call setState (which is protected)
  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _priceCtr.dispose();
    _platformCtr.dispose();
    _catCtr.dispose();
    _firstPriceCtr.dispose();
    _totalAccumulatedPriceCtr.dispose();
    super.dispose();
  }
  
  Future<void> _pickCustomIcon() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪图片',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: '裁剪图片',
          ),
        ],
      );

      if (croppedFile != null) {
        // Save to Application Documents Directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(croppedFile.path);
        // Ensure unique name to avoid conflicts if needed, but basename is usually fine from cropper
        // Or generate uuid
        final savedImage = await File(croppedFile.path).copy('${appDir.path}/$fileName');
        
        setState(() {
          _customIconPath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  void _removeCustomIcon() {
    setState(() {
      _customIconPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.device != null ? '编辑物品' : '添加物品')),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.direction == ScrollDirection.reverse)
                  ref.read(bottomNavBarVisibleProvider.notifier).state = false;
                else if (n.direction == ScrollDirection.forward)
                  ref.read(bottomNavBarVisibleProvider.notifier).state = true;
                return true;
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BasicInfoSection(
                      nameController: _nameCtr,
                      priceController: _priceCtr,
                      customPlatformController: _platformCtr,
                      customCategoryController: _catCtr,
                      selectedCategory: _selectedCategory,
                      selectedPlatform: _selectedPlatform,
                      customIconPath: _customIconPath,
                      onPickCustomIcon: _pickCustomIcon,
                      onRemoveCustomIcon: _removeCustomIcon,
                      onCategorySelected: (c) {
                        setState(() {
                          _selectedCategory = c;
                          if (c != null && widget.device == null) {
                            _nameCtr.text = c.name;
                          }
                          if (_isSub) {
                            if (_nextBillingDate == null)
                              _calculateNextBilling();
                            _isAutoRenew = false;
                            _hasReminder = false;
                          }
                        });
                      },
                      onPlatformSelected: (p) =>
                          setState(() => _selectedPlatform = p),
                    ),
                    const SizedBox(height: 16),
                    if (_isSub)
                      SubscriptionSection(
                        priceController: _priceCtr,
                        firstPeriodPriceController: _firstPriceCtr,
                        totalAccumulatedPriceController:
                            _totalAccumulatedPriceCtr,
                        purchaseDate: _purchaseDate,
                        nextBillingDate: _nextBillingDate,
                        cycleType: _cycleType,
                        isAutoRenew: _isAutoRenew,
                        hasReminder: _hasReminder,
                        reminderDays: _reminderDays,
                        hasFirstPeriodDiscount: _discount,
                        device: widget.device,
                        onCycleTypeChanged: (v) => setState(() {
                          _cycleType = v;
                          _calculateNextBilling();
                        }),
                        onAutoRenewChanged: (v) => setState(() {
                          _isAutoRenew = v;
                          if (!v) _discount = false;
                        }),
                        onReminderChanged: (v) =>
                            setState(() => _hasReminder = v),
                        onReminderDaysChanged: (v) =>
                            setState(() => _reminderDays = v),
                        onDiscountChanged: (v) => updateState(() {
                          _discount = v;
                          _updateTotalStr();
                        }),
                        onPickDate: () => _pickDate(),
                        onPickBillingDate: () => _pickDate(isBilling: true),
                        onShowRenewDialog: _showRenewDialog,
                      )
                    else
                      DateSection(
                        purchaseDate: _purchaseDate,
                        warrantyDate: _warrantyDate,
                        backupDate: _backupDate,
                        scrapDate: _scrapDate,
                        onPickDate: (w, b, s, billing) => _pickDate(
                          isWarranty: w,
                          isBackup: b,
                          isScrap: s,
                          isBilling: billing,
                        ),
                        onClearBackupDate: (_) =>
                            setState(() => _backupDate = null),
                        onClearScrapDate: (_) =>
                            setState(() => _scrapDate = null),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text: '保存',
                onPressed: _saveDevice,
                isLoading: _isLoading,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
