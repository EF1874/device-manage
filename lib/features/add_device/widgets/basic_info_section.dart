import 'package:flutter/material.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'category_picker.dart';
import 'platform_picker.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController customPlatformController;
  final TextEditingController customCategoryController;
  final Category? selectedCategory;
  final String? selectedPlatform;
  final Function(Category?) onCategorySelected;
  final Function(String?) onPlatformSelected;

  const BasicInfoSection({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.customPlatformController,
    required this.customCategoryController,
    required this.selectedCategory,
    required this.selectedPlatform,
    required this.onCategorySelected,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: nameController,
          label: '名称',
          labelStyle: TextStyle(color: Theme.of(context).hintColor),
          validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
        ),
        const SizedBox(height: 16),
        CategoryPicker(
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),
        if (selectedCategory?.name == '其它') ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: customCategoryController,
            label: '请输入分类名称 (选填)',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: priceController,
                label: '价格',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PlatformPicker(
                selectedPlatform: selectedPlatform,
                onPlatformSelected: onPlatformSelected,
              ),
            ),
          ],
        ),
        if (selectedPlatform == '其它') ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: customPlatformController,
            label: '请输入平台名称',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
            validator: (v) => v?.isEmpty == true ? '请输入平台名称' : null,
          ),
        ],
      ],
    );
  }
}
