import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../utils/subscription_utils.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return SubscriptionService(deviceRepo);
});

class SubscriptionService {
  final DeviceRepository _deviceRepo;

  SubscriptionService(this._deviceRepo);

  /// Checks all auto-renew subscriptions and updates them if they are due.
  Future<void> checkAndRenewSubscriptions() async {
    final devices = await _deviceRepo.getAllDevices();
    final now = DateTime.now();
    for (final device in devices) {
      // Only process auto-renew subscriptions with valid cycles
      if (device.isAutoRenew &&
          device.nextBillingDate != null &&
          device.cycleType != null &&
          device.cycleType != CycleType.oneTime) {
        // Check if due
        if (device.nextBillingDate!.isBefore(now)) {
          // Clone device to avoid modifying processed object if Isar returns const/frozen (though Isar objects are mutable usually)
          // But here we modify directly.

          bool updated = _processRenewal(device, now);
          if (updated) {
            await _deviceRepo.updateDevice(device);
          }
        }
      }
    }
  }

  /// Recursively renews the device until nextBillingDate is in the future.
  /// Returns true if any renewal happened.
  bool _processRenewal(Device device, DateTime targetDate) {
    if (device.nextBillingDate == null || device.cycleType == null)
      return false;

    bool renewed = false;
    DateTime next = device.nextBillingDate!;

    // Safety break to prevent infinite loops if cycle is 0 or something weird
    int safetyCounter = 0;

    while (next.isBefore(targetDate) && safetyCounter < 1000) {
      // Snapshot current period
      final historyEntry = SubscriptionHistory()
        ..endDate = next
        ..price = device.price
        ..isAutoRenew = true
        ..cycleType = device.cycleType!;

      DateTime calculatedStart = next.subtract(_getDuration(device.cycleType!));
      if (device.history.isNotEmpty) {
        if (device.history.last.endDate != null) {
          calculatedStart = device.history.last.endDate!;
        }
      } else {
        if (calculatedStart.isBefore(device.purchaseDate)) {
          calculatedStart = device.purchaseDate;
        }
      }
      historyEntry.startDate = calculatedStart;

      List<SubscriptionHistory> newHistory = List.from(device.history);
      newHistory.add(historyEntry);
      device.history = newHistory;

      // Accumulate price
      device.totalAccumulatedPrice += device.price;

      // Calculate next date
      next = SubscriptionUtils.calculateNextBillingDate(
        next,
        device.cycleType!,
      );
      device.nextBillingDate = next;

      renewed = true;
      safetyCounter++;
    }

    return renewed;
  }

  /// Manually renews a subscription for a given number of cycles.
  Future<void> manualRenew(Device device, {int cycles = 1}) async {
    if (device.cycleType == null || device.cycleType == CycleType.oneTime)
      return;

    DateTime next = device.nextBillingDate ?? DateTime.now();

    for (int i = 0; i < cycles; i++) {
      // Snapshot current period before extending
      final historyEntry = SubscriptionHistory()
        ..endDate = next
        ..price = device
            .price // Renewal price
        ..isAutoRenew =
            false // Manual renewal
        ..cycleType = device.cycleType!;

      DateTime calculatedStart = next.subtract(_getDuration(device.cycleType!));
      if (device.history.isNotEmpty) {
        if (device.history.last.endDate != null) {
          calculatedStart = device.history.last.endDate!;
        }
      } else {
        if (calculatedStart.isBefore(device.purchaseDate)) {
          calculatedStart = device.purchaseDate;
        }
      }
      historyEntry.startDate = calculatedStart;

      List<SubscriptionHistory> newHistory = List.from(device.history);
      newHistory.add(historyEntry);
      device.history = newHistory;

      device.totalAccumulatedPrice += device.price;
      next = SubscriptionUtils.calculateNextBillingDate(
        next,
        device.cycleType!,
      );
    }

    device.nextBillingDate = next;
    await _deviceRepo.updateDevice(device);
  }

  Duration _getDuration(CycleType type) {
    switch (type) {
      case CycleType.daily:
        return const Duration(days: 1);
      case CycleType.weekly:
        return const Duration(days: 7);
      case CycleType.monthly:
        return const Duration(days: 30); // Approx
      case CycleType.quarterly:
        return const Duration(days: 90); // Approx
      case CycleType.yearly:
        return const Duration(days: 365); // Approx
      case CycleType.oneTime:
        return Duration.zero;
    }
  }
}
