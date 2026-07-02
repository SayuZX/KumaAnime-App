import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:hive/hive.dart';

Future<dynamic>? getVal(HiveKey itemKey, {HiveBox boxName = HiveBox.kumaanime}) async {
  var box = await Hive.openBox(boxName.boxName);
  if (!box.isOpen) {
    box = await Hive.openBox(boxName.boxName);
  }
  final vals = await box.get(itemKey.name);
  await box.close();
  return vals;
}

Future<void> storeVal(HiveKey itemKey, dynamic val, {HiveBox boxName = HiveBox.kumaanime}) async {
  try {
    var box = await Hive.openBox(boxName.boxName);
    if (!box.isOpen) {
      box = await Hive.openBox(boxName.boxName);
    }
    await box.put(itemKey.name, val);
    await box.close();
  } catch (err) {
    Logs.app.log(err.toString());
  }
}
