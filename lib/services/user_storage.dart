import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户资料本地存储
class UserStorage {
  static const String _keyAvatarPath = 'user_avatar_path';
  static const String _keyNickname = 'user_nickname';
  static const String _keySignature = 'user_signature';
  static const String _keyCoinBalance = 'user_coin_balance';
  static const String _keyPermanentVipActivated = 'permanent_vip_activated';
  static const String _keyPurchasedOneTimeProducts = 'purchased_one_time_products';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<String?> getAvatarPath() async {
    await init();
    return _prefs!.getString(_keyAvatarPath);
  }

  static Future<void> setAvatarPath(String relativePath) async {
    await init();
    await _prefs!.setString(_keyAvatarPath, relativePath);
  }

  static Future<String?> getNickname() async {
    await init();
    return _prefs!.getString(_keyNickname);
  }

  static Future<void> setNickname(String nickname) async {
    await init();
    await _prefs!.setString(_keyNickname, nickname);
  }

  static Future<String?> getSignature() async {
    await init();
    return _prefs!.getString(_keySignature);
  }

  static Future<void> setSignature(String signature) async {
    await init();
    await _prefs!.setString(_keySignature, signature);
  }

  static Future<int> getCoinBalance() async {
    await init();
    return _prefs!.getInt(_keyCoinBalance) ?? 0;
  }

  static Future<void> setCoinBalance(int balance) async {
    await init();
    await _prefs!.setInt(_keyCoinBalance, balance);
  }

  static Future<int> addCoins(int amount) async {
    await init();
    final current = _prefs!.getInt(_keyCoinBalance) ?? 0;
    final newBalance = current + amount;
    await _prefs!.setInt(_keyCoinBalance, newBalance);
    return newBalance;
  }

  static Future<Set<String>> getPurchasedOneTimeProducts() async {
    await init();
    final list = _prefs!.getStringList(_keyPurchasedOneTimeProducts) ?? [];
    return list.toSet();
  }

  static Future<void> addPurchasedOneTimeProduct(String productId) async {
    await init();
    final list = _prefs!.getStringList(_keyPurchasedOneTimeProducts) ?? [];
    list.add(productId);
    await _prefs!.setStringList(_keyPurchasedOneTimeProducts, list);
  }

  static Future<bool> isPermanentVipActivated() async {
    await init();
    return _prefs!.getBool(_keyPermanentVipActivated) ?? false;
  }

  static Future<void> setPermanentVipActivated(bool activated) async {
    await init();
    await _prefs!.setBool(_keyPermanentVipActivated, activated);
  }

  /// 获取应用文档目录
  static Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// 根据相对路径获取完整路径
  static Future<String> getFullPath(String relativePath) async {
    final dir = await getDocumentsDirectory();
    return '${dir.path}/$relativePath';
  }
}
