import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:xlist/gen/index.dart';
import 'package:xlist/common/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/constants/index.dart';
import 'package:xlist/database/entity/index.dart';
import 'package:xlist/pages/setting/favorite/index.dart';

class FavoritePage extends GetView<FavoriteController> {
  const FavoritePage({Key? key, this.showBackButton = true})
      : super(key: key);

  /// 是否显示返回按钮 (嵌入主页标签页时为 false)
  final bool showBackButton;

  // NavigationBar
  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: CommonUtils.backgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: showBackButton ? CommonUtils.backButton : null,
      middle: Text('favorite'.tr),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text('setting_recent_clear'.tr),
        onPressed: () => controller.clearFavorite(),
      ),
    );
  }

  /// 构建预览图或图标
  /// [entity] 收藏实体
  Widget _buildIcon(FavoriteEntity entity) {
    // 预览图地址: 优先使用服务端缩略图, 图片文件降级为直链预览
    String? url = entity.thumb;
    if (url == null || url.isEmpty) {
      if (PreviewHelper.isImage(entity.name)) {
        url = CommonUtils.getDownloadLink(
          entity.path,
          object: ObjectModel.fromJson(
              {'name': entity.name, 'sign': entity.sign ?? ''}),
          userInfo: UserModel.fromJson({'base_path': '/'}),
        );
      }
    }

    // 显示预览图
    if (url != null && url.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: CommonUtils.isPad ? 60 : 130.sp,
            height: CommonUtils.isPad ? 60 : 130.sp,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    CupertinoActivityIndicator(radius: 8.0),
                errorWidget: (context, url, error) => Icon(
                  FileType.getIcon(entity.type, entity.name),
                  size: CommonUtils.isPad ? 60 : 130.sp,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
          ),
          PreviewHelper.isVideo(entity.name)
              ? Positioned(
                  bottom: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Icon(
                      CupertinoIcons.video_camera_solid,
                      size: CommonUtils.isPad ? 20 : 35.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
              : SizedBox(),
        ],
      );
    }

    // 显示文件类型图标
    return Icon(
      FileType.getIcon(entity.type, entity.name),
      size: CommonUtils.isPad ? 60 : 130.sp,
      color: Get.theme.primaryColor,
    );
  }

  /// 列表项
  Widget _buildItem(FavoriteEntity entity) {
    String path = entity.path;
    if (entity.path.endsWith('/')) {
      path = entity.path.substring(0, entity.path.length - 1);
    }

    return CupertinoListSection.insetGrouped(
      backgroundColor: CommonUtils.backgroundColor,
      margin: EdgeInsets.zero,
      children: [
        Container(
          height: CommonUtils.isPad ? 80 : 170.h,
          width: double.infinity,
          child: Slidable(
            endActionPane: ActionPane(
              motion: ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => controller.deleteFavorite(entity),
                  backgroundColor: Colors.red,
                  icon: CupertinoIcons.delete,
                  label: 'delete'.tr,
                ),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async => ObjectHelper.click(
                path: entity.path,
                type: entity.type,
                name: entity.name,
                objects: await controller.getObjectList(entity),
              ),
              child: Row(
                children: [
                  SizedBox(width: CommonUtils.isPad ? 15 : 30.w),
                  _buildIcon(entity),
                  SizedBox(width: CommonUtils.isPad ? 10 : 20.w),
                  Container(
                    width: 750.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: CommonUtils.isPad ? 15 : 30.h),
                        Text(
                          entity.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Get.textTheme.bodyLarge,
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          '${entity.type == FileType.FOLDER ? '∞' : CommonUtils.formatFileSize(entity.size)}${path.isNotEmpty ? ' - $path' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Get.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SliverList
  Widget _buildSliverList() {
    return PagedSliverList<int, FavoriteEntity>.separated(
      pagingController: controller.pagingController,
      separatorBuilder: (context, index) => SizedBox(height: 30.h),
      builderDelegate: PagedChildBuilderDelegate<FavoriteEntity>(
        animateTransitions: false,
        noItemsFoundIndicatorBuilder: (context) => _buildEmptyData(),
        firstPageProgressIndicatorBuilder: (context) => _buildLoading(),
        newPageProgressIndicatorBuilder: (context) => _buildLoading(),
        itemBuilder: (context, item, index) {
          return FrameSeparateWidget(
            index: index,
            child: _buildItem(item),
          );
        },
      ),
    );
  }

  /// Loading
  Widget _buildLoading() {
    return Center(child: CupertinoActivityIndicator());
  }

  /// EmptyData
  Widget _buildEmptyData() {
    return Column(
      children: [
        SizedBox(height: 500.h),
        Assets.images.empty.image(width: 600.r),
        SizedBox(height: 30.h),
        Text('setting_favorite_empty'.tr, style: Get.textTheme.bodyLarge),
      ],
    );
  }

  // ScrollView
  // Replace to [NestedScrollView]
  Widget _buildCustomScrollView() {
    return CustomScrollView(
      shrinkWrap: false,
      physics: AlwaysScrollableScrollPhysics(),
      controller: controller.scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Obx(
            () => controller.isEmpty.isFalse
                ? Container(
                    padding: CommonUtils.isPad
                        ? EdgeInsets.only(left: 40, top: 30.h, bottom: 10.h)
                        : EdgeInsets.only(left: 80.w, top: 30.h, bottom: 10.h),
                    child: Text(
                      'setting_favorite_description'.tr,
                      style: Get.textTheme.bodySmall,
                    ),
                  )
                : SizedBox(),
          ),
        ),
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: 50.r).copyWith(bottom: 50.h),
          sliver: SizeCacheWidget(child: _buildSliverList()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      backgroundColor: CommonUtils.backgroundColor,
      child: _buildCustomScrollView(),
    );
  }
}
