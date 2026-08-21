import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:xlist/common/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/components/index.dart';
import 'package:xlist/routes/app_pages.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/database/entity/index.dart';
import 'package:xlist/pages/setting/favorite/index.dart';
import 'package:xlist/pages/setting/recent/index.dart';
import 'package:xlist/services/browser_service.dart';

class Homepage extends GetView<HomepageController> {
  const Homepage({Key? key}) : super(key: key);

  /// NavigationBar
  Widget _buildSliverNavigationBar() {
    return CupertinoSliverNavigationBar(
      backgroundColor:
          Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        child: Container(
          width: 190.w,
          child: Row(
            children: [
              Icon(CupertinoIcons.umbrella_fill, size: CommonUtils.navIconSize),
              SizedBox(width: 15.w),
              // Text('设置', style: TextStyle(fontSize: 50.sp)),
            ],
          ),
        ),
        onPressed: () => Get.toNamed(Routes.SETTING)
            ?.then((value) => controller.getObjectList()),
      ),
      largeTitle: Text(
        'homepage_title'.tr,
        style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
      ),
      trailing: Obx(
        () => ButtonHelper.createPullDownButton(
          controller: controller,
          path: '/',
          source: PageSource.HOMEPAGE,
          pageTag: tag ?? '',
        ),
      ),
    );
  }

  /// 无设置服务器
  Widget _buildEmptyServer() {
    return Column(
      children: [
        SizedBox(height: 500.h),
        Text(
          'homepage_empty_server_title'.tr,
          style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: CommonUtils.isPad ? 20 : 50.sp,
              ),
              SizedBox(width: 5.w),
              Text('homepage_empty_server_help'.tr),
            ],
          ),
          onPressed: () => BrowserService.to.open('https://alist.nn.ci'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 100.r),
          child: ButtonHelper.createElevatedButton(
            'homepage_empty_server_button'.tr,
            onPressed: () async {
              final result = await BottomSheetHelper.showBottomSheet(
                AddServerBottomSheet(),
              );
              if (result == null) return;
              if (!(result is ServerEntity)) return;

              // 重置本地信息
              Get.find<UserStorage>().serverId.val = result.id!;
              Get.find<UserStorage>().serverUrl.val = result.url;

              // 重置首页信息
              controller.serverId.value = result.id!;
              await controller.resetUserToken(result);
              controller.getObjectList();
            },
          ),
        ),
      ],
    );
  }

  /// SliverList
  Widget _buildSliverList() {
    if (controller.isFirstLoading.isTrue) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 500.h),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return SizeCacheWidget(
      child: controller.layoutType.value == LayoutType.GRID
          ? ObjectGridComponent(
              tag: '',
              source: PageSource.HOMEPAGE,
              userInfo: controller.userInfo.value,
              path: '/',
              objects: controller.objects.value,
              isShowPreview: controller.isShowPreview.value,
            )
          : ObjectListComponent(
              tag: '',
              source: PageSource.HOMEPAGE,
              userInfo: controller.userInfo.value,
              path: '/',
              objects: controller.objects.value,
              isShowPreview: controller.isShowPreview.value,
            ),
    );
  }

  // ScrollView
  // Replace to [NestedScrollView]
  Widget _buildCustomScrollView() {
    return CustomScrollView(
      shrinkWrap: false,
      controller: controller.scrollController,
      slivers: <Widget>[
        _buildSliverNavigationBar(),
        HeaderLocator.sliver(),
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: CommonUtils.isPad ? 20 : 50.r)
                  .copyWith(bottom: 30.h),
          sliver: SliverToBoxAdapter(child: SearchComponent(path: '/')),
        ),
        Obx(
          () => SliverPadding(
            padding:
                EdgeInsets.symmetric(horizontal: CommonUtils.isPad ? 15 : 30.r),
            sliver: controller.serverId.value == 0 &&
                    controller.isFirstLoading.isFalse
                ? SliverToBoxAdapter(child: _buildEmptyServer())
                : _buildSliverList(),
          ),
        ),
        FooterLocator.sliver(),
      ],
    );
  }

  // 底部导航栏 (currentIndex/onTap 由 CupertinoTabScaffold 注入)
  CupertinoTabBar _buildTabBar() {
    return CupertinoTabBar(
      backgroundColor:
          Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
      border: Border.all(width: 0, color: Colors.transparent),
      items: [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.folder_fill,
              size: CommonUtils.navIconSize),
          label: 'homepage_tab_files'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.star_fill, size: CommonUtils.navIconSize),
          label: 'favorite'.tr,
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.clock_fill, size: CommonUtils.navIconSize),
          label: 'recent'.tr,
        ),
      ],
    );
  }

  /// 标签页视图
  /// 每个标签页拥有独立的嵌套导航器, 页面跳转发生在嵌套导航器内,
  /// 从而保证底部导航栏 (文件/收藏/最近浏览) 始终置顶显示。
  ///
  /// [id] 嵌套导航器 ID
  /// [builder] 标签页根内容
  Widget _buildTabView(int id, {required WidgetBuilder builder}) {
    return CupertinoTabView(
      navigatorKey: Get.nestedKey(id),
      navigatorObservers: [GetObserver(null, Get.routing)],
      onGenerateRoute: (settings) => PageRedirect(
        settings: settings,
        unknownRoute: AppPages.unknownRoute,
      ).page(),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    // CupertinoTabView 内置 NavigatorPopHandler:
    // 系统返回键会优先弹出当前标签页嵌套导航器中的页面
    return CupertinoTabScaffold(
      controller: controller.tabController,
      tabBar: _buildTabBar(),
      tabBuilder: (context, index) {
        switch (index) {
          case 0: // 文件
            return _buildTabView(
              NavigatorHelper.FILES_TAB_ID,
              builder: (_) => _buildFilesTab(),
            );
          case 1: // 收藏
            return _buildTabView(
              NavigatorHelper.FAVORITE_TAB_ID,
              builder: (_) => FavoritePage(showBackButton: false),
            );
          case 2: // 最近浏览
          default:
            return _buildTabView(
              NavigatorHelper.RECENT_TAB_ID,
              builder: (_) => RecentPage(showBackButton: false),
            );
        }
      },
    );
  }

  // 文件标签页 (原首页内容)
  Widget _buildFilesTab() {
    return EasyRefresh(
      controller: controller.easyRefreshController,
      header: CupertinoHeader(
          position: IndicatorPosition.locator, safeArea: false),
      footer: CupertinoFooter(position: IndicatorPosition.locator),
      onRefresh: () async {
        await HapticFeedback.selectionClick();
        await controller.getObjectList();
        controller.easyRefreshController.finishRefresh();
        controller.easyRefreshController.resetFooter();
      },
      child: _buildCustomScrollView(),
    );
  }
}
