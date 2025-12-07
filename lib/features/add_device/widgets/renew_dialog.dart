import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';

class RenewDialog extends StatefulWidget {
  final CycleType initialCycleType;
  final double initialPrice;

  const RenewDialog({
    super.key,
    required this.initialCycleType,
    required this.initialPrice,
  });

  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  late CycleType _selectedCycle;
  late double _renewPrice;

  @override
  void initState() {
    super.initState();
    _selectedCycle = widget.initialCycleType;
    _renewPrice = widget.initialPrice;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动续费'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<CycleType>(
            decoration: const InputDecoration(labelText: '续费周期'),
            value: _selectedCycle,
            items:
                [
                  CycleType.daily,
                  CycleType.weekly,
                  CycleType.monthly,
                  CycleType.quarterly,
                  CycleType.yearly,
                ].map((e) {
                  String label;
                  switch (e) {
                    case CycleType.daily:
                      label = '1天';
                      break;
                    case CycleType.weekly:
                      label = '1周';
                      break;
                    case CycleType.monthly:
                      label = '1月';
                      break;
                    case CycleType.quarterly:
                      label = '1季';
                      break;
                    case CycleType.yearly:
                      label = '1年';
                      break;
                    default:
                      label = '';
                  }
                  return DropdownMenuItem(value: e, child: Text(label));
                }).toList(),
            onChanged: (v) => setState(() => _selectedCycle = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _renewPrice.toString(),
            decoration: const InputDecoration(labelText: '续费金额'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _renewPrice = double.tryParse(v) ?? 0.0,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'cycle': _selectedCycle,
              'price': _renewPrice,
            });
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
