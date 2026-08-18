import 'dart:io';
import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:xlist/services/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/database/entity/index.dart';

// 全局配置
class Global {
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;
  static bool get isDebug => kDebugMode;

  // 运行初始化
  static Future<void> init() async {
    // Init FlutterBinding
    WidgetsFlutterBinding.ensureInitialized();

    // HttpOverrides
    HttpOverrides.global = XlistHttpOverrides();

    // GetStorage
    await GetStorage.init();

    // Storage
    await Get.put(CommonStorage());
    await Get.putAsync(() => UserStorage().init());
    await Get.putAsync(() => PreferencesStorage().init());

    // Init Getx Service
    await Get.put(BrowserService());
    await Get.putAsync(() => DioService().init());
    await Get.putAsync(() => DatabaseService().init());
    await Get.putAsync(() => DownloadService().init());
    await Get.putAsync(() => DeviceInfoService().init());
    await Get.putAsync(() => PlayerNotificationService().init());

    // 播种默认服务器 (未配置任何服务器时自动添加并登录)
    try {
      final userStorage = Get.find<UserStorage>();
      if (userStorage.serverId.val == 0) {
        final servers =
            await DatabaseService.to.database.serverDao.findAllServer();
        if (servers.isEmpty) {
          final serverId = await DatabaseService.to.database.serverDao
              .insertServer(ServerEntity(
            url: DefaultServer.url,
            type: ServerType.ALIST,
            username: DefaultServer.username,
            password: DefaultServer.password,
          ));

          // 重置本地服务器信息, 首页启动时会自动登录获取 token
          userStorage.serverId.val = serverId;
          userStorage.serverUrl.val = DefaultServer.url;
        }
      }
    } catch (e) {
      debugPrint('seed default server failed: $e');
    }

    // 读取设备第一次打开
    final isFirstOpen = Get.find<PreferencesStorage>().isFirstOpen;
    if (isFirstOpen.val == true) {
      isFirstOpen.val = false;

      // IOS 请求联网弹窗
      try {
        if (GetPlatform.isIOS) DioService.to.dio.get('https://xlist.site');
      } catch (e) {}
    }

    // Theme
    Get.changeThemeMode(ThemeModeMap[Get.find<CommonStorage>().themeMode.val]!);

    // android 状态栏为透明的沉浸
    if (GetPlatform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}

class XlistHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // allowLegacyUnsafeRenegotiation
    final SecurityContext sc = SecurityContext();
    sc.allowLegacyUnsafeRenegotiation = true;

    return super.createHttpClient(sc)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
