import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../../shared/config/category_config.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return CategoryRepository(dbService.isar);
});

class CategoryRepository {
  final Isar _isar;

  CategoryRepository(this._isar);

  Future<List<Category>> getAllCategories() async {
    return await _isar.categorys.where().findAll();
  }

  Future<void> addCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(id);
    });
  }
  
  Future<void> initDefaultCategories() async {
    final count = await _isar.categorys.count();
    if (count == 0) {
      final defaults = CategoryConfig.defaultCategories.map((item) {
        return Category()
          ..name = item.name
          ..iconPath = item.iconPath
          ..isDefault = true;
      }).toList();
      
      await _isar.writeTxn(() async {
        await _isar.categorys.putAll(defaults);
      });
    }
  }
}
