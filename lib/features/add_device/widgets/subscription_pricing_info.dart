import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SubscriptionPricingInfo extends StatelessWidget {
  final TextEditingController priceController;
  final double totalAccumulatedPrice;

  const SubscriptionPricingInfo({
    super.key,
    required this.priceController,
    required this.totalAccumulatedPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '总投入',
              border: OutlineInputBorder(),
            ),
            child: Text(
              '¥${totalAccumulatedPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
