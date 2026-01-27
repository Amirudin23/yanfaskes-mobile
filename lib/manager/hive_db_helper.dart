import 'dart:async';
import 'package:hive/hive.dart';

class HiveDbServices {
  static const String boxHospital = 'DAC_Hospital';
  static const String boxRoom = 'DAC_Room';
  static const String boxTransaction = 'DAC_Transaction';

  Future<Box> _openBox(String key) async => await Hive.openBox(key);

  Future<bool> addData(String key, dynamic data) async {
    var box = await _openBox(key);
    bool isSaved = false;
    if (data != null) {
      var inserted = box.put(key, data);
      // ignore: unnecessary_null_comparison
      if(inserted != null){
        isSaved = true;
      }
    }
    return isSaved;
  }

  Future<dynamic> getData(String key) async {
    var box = await _openBox(key);
    return box.get(key);
  }

  Future<bool> hasData(String key) async {
    var box = await _openBox(key);
    var value = box.get(key);
    return (value != null ? true : false);
  }

  Future<void> deleteData(String key) async {
    var box = await _openBox(key);
    var data = box.delete(key);
    return data;
  }
}
