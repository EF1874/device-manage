import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> vehiclesCategories = [
  const CategoryItem(
    name: '轿车',
    iconPath: 'MdiIcons.car',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '摩托车',
    iconPath: 'MdiIcons.motorbike',
    color: Colors.red,
  ),
  const CategoryItem(
    name: '电动车/小电驴',
    iconPath: 'MdiIcons.moped',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '车钥匙',
    iconPath: 'MdiIcons.carKey',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '交通卡/地铁卡',
    iconPath: 'MdiIcons.cardBulleted',
    color: Colors.blue,
  ),

  // --- 🚗 新增：车载用品/配件 ---
  const CategoryItem(
    name: '行车记录仪',
    iconPath: 'MdiIcons.webcam',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: 'ETC设备',
    iconPath: 'MdiIcons.creditCardWireless',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '车载手机支架',
    iconPath: 'MdiIcons.cellphoneDock',
    color: Colors.cyan, // Changed from Grey
  ),
  const CategoryItem(
    name: '车载充电器',
    iconPath: 'MdiIcons.carBattery',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '充气泵',
    iconPath: 'MdiIcons.airFilter', // MDI doesn't have pump specific, airFilter usage
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '安全座椅',
    iconPath: 'MdiIcons.seatPassenger',
    color: Colors.redAccent,
  ),
];
