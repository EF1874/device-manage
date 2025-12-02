import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return DeviceRepository(dbService.isar, backupService);
});

class DeviceRepository {
  final Isar _isar;
  final BackupService _backupService;

  DeviceRepository(this._isar, this._backupService);

  Future<List<Device>> getAllDevices() async {
    return await _isar.devices.where().findAll();
  }

  Stream<List<Device>> watchAllDevices() {
    return _isar.devices.where().watch(fireImmediately: true);
  }

  Future<void> addDevice(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
    // Trigger backup after adding device
    _backupService.createBackup();
  }

  Future<void> updateDevice(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
    // Trigger backup after updating device
    _backupService.createBackup();
  }

  Future<void> deleteDevice(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.devices.delete(id);
    });
    // Trigger backup after deleting device
    _backupService.createBackup();
  }
}
