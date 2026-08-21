import 'package:get/get.dart';

import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/pages/detail/index.dart';

/// 嵌套导航工具类
///
/// 首页使用 [CupertinoTabScaffold] + [CupertinoTabView] 实现底部导航栏常驻,
/// 每个标签页拥有独立的嵌套导航器 (通过 [Get.nestedKey] 注册),
/// 文件浏览等页面在嵌套导航器内跳转, 底部导航栏始终可见。
///
/// 设置页 / 目录选择页 / 媒体预览页等全屏页面仍使用根导航器。
class NavigatorHelper {
  /// 嵌套导航器 ID: 1 文件 / 2 收藏 / 3 最近浏览
  static const int FILES_TAB_ID = 1;
  static const int FAVORITE_TAB_ID = 2;
  static const int RECENT_TAB_ID = 3;

  /// 获取当前激活标签页的嵌套导航器 ID
  static int get currentTabId {
    if (!Get.isRegistered<HomepageController>()) return FILES_TAB_ID;
    return Get.find<HomepageController>().tabController.index + 1;
  }

  /// 根导航器是否有页面覆盖在首页之上
  /// (设置页 / 设置子页 / 目录选择页 / 媒体预览页 / 弹窗等)
  ///
  /// 为 true 时当前处于全屏页面中, 跳转应使用根导航器;
  /// 为 false 时当前处于首页标签视图内, 跳转应使用当前标签页的嵌套导航器,
  /// 从而保证底部导航栏 (文件/收藏/最近浏览) 始终置顶显示。
  static bool get isRootNavigatorActive =>
      Get.key.currentState?.canPop() ?? false;

  /// 获取当前页面跳转应使用的导航器 ID
  /// 返回 null 表示使用根导航器
  static int? get currentNavigatorId =>
      isRootNavigatorActive ? null : currentTabId;

  /// 打开文件夹详情页
  ///
  /// [path] 文件路径
  /// [name] 文件名称
  static void toDetail({required String path, required String name}) {
    final tag = '${path}${name}';
    Get.to(
      () => DetailPage(tag: tag, previousPageTitle: '返回'),
      id: currentNavigatorId,
      routeName: '${Routes.DETAIL}${tag}',
      arguments: {'path': path, 'name': name},
      preventDuplicates: false,
    );
  }

  /// 打开搜索页
  ///
  /// [path] 搜索路径
  static void toSearch({required String path}) {
    Get.toNamed(
      Routes.SEARCH,
      id: currentNavigatorId,
      arguments: {'path': path},
      preventDuplicates: false,
    );
  }

  /// 智能返回
  ///
  /// 根导航器有上层页面时弹出根导航器 (设置页 / 预览页 / 弹窗等),
  /// 否则弹出当前标签页嵌套导航器中的页面。
  static void back<T>({T? result}) {
    // 根导航器有上层页面: 弹出根导航器
    if (isRootNavigatorActive) {
      Get.back(result: result);
      return;
    }

    // 标签视图内: 优先弹出当前标签页嵌套导航器中的页面
    final nestedState = Get.nestedKey(currentTabId)?.currentState;
    if (nestedState?.canPop() == true) {
      Get.back(result: result, id: currentTabId);
      return;
    }

    // 嵌套导航器无页面可弹, 交由根导航器处理
    Get.back(result: result);
  }

  /// 重置所有标签页嵌套导航器到根页面
  /// (切换 / 删除服务器后清除旧的目录栈)
  static void resetTabs() {
    for (final id in [FILES_TAB_ID, FAVORITE_TAB_ID, RECENT_TAB_ID]) {
      Get.nestedKey(id)?.currentState?.popUntil((route) => route.isFirst);
    }
  }

  /// 一键返回主页 (浏览页右下角悬浮按钮)
  ///
  /// 标签视图内: 弹出当前标签页嵌套导航器的全部目录页, 回到标签根
  /// (文件标签 → 主页, 收藏/最近浏览标签 → 对应列表);
  /// 全屏页面栈 (设置-收藏/最近浏览进入的详情页): 弹出全部页面回到首页。
  static void backToHome() {
    if (isRootNavigatorActive) {
      Get.key.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    Get.nestedKey(currentTabId)
        ?.currentState
        ?.popUntil((route) => route.isFirst);
  }

  /// 弹出根导航器中的目录选择页
  /// (移动 / 复制操作完成后调用, 详情页可能位于嵌套导航器或根导航器)
  static void popDirectoryPages() {
    Get.until(
      (route) => !(route.settings.name ?? '').startsWith(Routes.DIRECTORY),
    );
  }
}
