import 'package:isar/isar.dart';
import 'category.dart';

part 'device.g.dart';

@collection
class Device {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  @Index()
  String? uuid;

  final category = IsarLink<Category>();

  late double price;

  late DateTime purchaseDate;

  late String platform;

  DateTime? warrantyEndDate;

  DateTime? scrapDate;

  DateTime? backupDate;

  // Subscription Fields
  @Enumerated(EnumType.name)
  CycleType? cycleType;

  bool isAutoRenew = true;

  DateTime? nextBillingDate;

  int reminderDays = 1;

  bool hasReminder = false;

  @ignore
  String get status {
    if (scrapDate != null) return 'scrap';
    if (backupDate != null) return 'backup';
    return 'in_use';
  }

  @ignore
  double get dailyCost {
    DateTime end = DateTime.now();
    bool isSub = cycleType != null && cycleType != CycleType.oneTime;

    if (isSub) {
      // For subscriptions:
      // If AutoRenew: active until Now.
      // If Not AutoRenew: active until NextBillingDate (Expiration).
      if (!isAutoRenew && nextBillingDate != null) {
        if (nextBillingDate!.isBefore(end)) {
          end = nextBillingDate!;
        }
      }

      // Calculate Total Cost
      // We assume 'price' is Per Cycle.
      // We need to count cycles from purchaseDate to end.
      int cycles = 1;
      // Simple logic: add cycle duration until > end
      // This is expensive for dailyCost if many cycles, but accurate.
      // Optimization: use diff.
      int days = end.difference(purchaseDate).inDays;
      if (days <= 0) days = 1;

      // Estimate cycles based on days
      // Monthly ~ 30, Yearly ~ 365, Weekly ~ 7
      // For better accuracy we might iterate or use strict calendar math if needed.
      // Let's iterate for correctness but limit it?
      // Or just return price/cycle_days? No, daily cost should be average.
      // Actually: Average Daily Cost for Sub = Price / CycleDays.
      // e.g. $10 / 30 days = $0.33/day.
      // Regardless of how long you used it, the RATE is constant.
      // UNLESS the price changed, but we only have one price.
      // So Subscription Daily Cost = Cost Per Cycle / Days In Cycle.

      switch (cycleType) {
        case CycleType.weekly:
          return price / 7;
        case CycleType.monthly:
          return price / 30; // Approx
        case CycleType.yearly:
          return price / 365;
        case null:
        case CycleType.oneTime:
          break;
      }
    }

    // Standard Non-Sub Logic (or OneTime)
    final endDate = scrapDate ?? DateTime.now();
    final days = endDate.difference(purchaseDate).inDays;
    if (days <= 0) return price; // Avoid division by zero
    return price / days;
  }

  @ignore
  int get daysUsed {
    final endDate = scrapDate ?? DateTime.now();
    return endDate.difference(purchaseDate).inDays;
  }
}

enum CycleType { monthly, yearly, weekly, oneTime }
