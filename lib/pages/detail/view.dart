import 'dart:ui' show ImageFilter;

import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:xlist/common/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/components/index.dart';
import 'package:xlist/pages/detail/index.dart';

class DetailPage extends StatelessWidget {
  final String? tag;
  final String? previousPageTitle;
  DetailController get controller => Get.find<DetailController>(tag: tag);

  /// 构造函数
  DetailPage({Key? key, this.tag, this.previousPageTitle}) : super(key: key) {
    Get.put<DetailController>(DetailController(), tag: tag);
  }

  // NavigationBar
  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CommonUtils.backButton,
      middle: Text(
        controller.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Obx(
        () => ButtonHelper.createPullDownButton(
          controller: controller,
          path: '${controller.path}${controller.name}',
          source: PageSource.DETAIL,
          pageTag: tag ?? '',
          favoriteFolderPath: controller.path,
          favoriteFolderName: controller.name,
        ),
      ),
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
              tag: tag ?? '',
              source: PageSource.DETAIL,
              userInfo: controller.userInfo.value,
              path: '${controller.path}${controller.name}/',
              objects: controller.objects.value,
              isShowPreview: controller.isShowPreview.value,
            )
          : ObjectListComponent(
              tag: tag ?? '',
              source: PageSource.DETAIL,
              userInfo: controller.userInfo.value,
              path: '${controller.path}${controller.name}/',
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
        HeaderLocator.sliver(),
        SliverPadding(
          padding: EdgeInsets.symmetric(
              horizontal: CommonUtils.isPad ? 20 : 50.r, vertical: 30.r),
          sliver: SliverToBoxAdapter(
            child: SearchComponent(
              path: '${controller.path}${controller.name}',
            ),
          ),
        ),
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: CommonUtils.isPad ? 15 : 30.r),
          sliver: Obx(() => _buildSliverList()),
        ),
        FooterLocator.sliver(),
      ],
    );
  }

  /// 主页悬浮按钮 (单手操作优化)
  ///
  /// 右下角拇指热区, 毛玻璃圆钮;
  /// 向下浏览时淡出缩放隐藏, 向上滚动时恢复, 不遮挡列表内容。
  Widget _buildHomeFloatingButton() {
    return Positioned(
      right: CommonUtils.isPad ? 20.0 : 45.r,
      bottom: CommonUtils.isPad ? 20.0 : 45.r,
      child: Obx(
        () {
          final visible = controller.isShowHomeButton.value;
          return IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: visible ? 1.0 : 0.65,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: const _HomeFabButton(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        // Stack: 滚动内容 + 主页悬浮按钮 (悬浮于右下角, 不随列表滚动)
        child: Stack(
          children: [
            EasyRefresh(
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
            ),
            _buildHomeFloatingButton(),
          ],
        ),
      ),
    );
  }
}

/// 主页悬浮按钮
///
/// 毛玻璃圆形按钮, 单击一键返回主页 (清空当前标签页的目录栈),
/// 位置在底部导航栏上方右侧, 属于拇指自然热区, 适合单手操作。
class _HomeFabButton extends StatelessWidget {
  const _HomeFabButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final size = CommonUtils.isPad ? 56.0 : 150.w;
    final iconSize = CommonUtils.isPad ? 28.0 : 64.sp;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(size / 2),
      minSize: 0,
      onPressed: () => NavigatorHelper.backToHome(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: isDark
                  ? const Color.fromARGB(185, 40, 40, 45)
                  : const Color.fromARGB(170, 255, 255, 255),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.house_fill,
                size: iconSize,
                color: Get.theme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
