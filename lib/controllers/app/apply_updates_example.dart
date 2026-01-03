
import 'apply_updates_controller.dart';

/// 使用示例
/// 
/// 示例代码：
/// ```dart
/// // 获取当前平台的更新控制器
/// final controller = ApplyUpdatesFactory.getController();
/// 
/// // 调用更新方法
/// controller.applyUpdates('https://example.com/update/app.apk');
/// ```
/// 
/// 在 GetX Controller 中使用：
/// ```dart
/// class AppInfoController extends GetxController {
///   void checkAndUpdate(String downloadUrl) {
///     try {
///       final updateController = ApplyUpdatesFactory.getController();
///       updateController.applyUpdates(downloadUrl);
///     } catch (e) {
///       Get.log('更新失败: $e');
///     }
///   }
/// }
/// ```
class ApplyUpdatesExample {
  /// 示例：如何在不同场景中使用更新控制器
  static void example() {
    // 1. 基本使用
    final controller = ApplyUpdatesFactory.getController();
    controller.applyUpdates('https://example.com/update/app.apk');

    // 2. 在 try-catch 中使用（推荐）
    try {
      final updateController = ApplyUpdatesFactory.getController();
      updateController.applyUpdates('https://example.com/update/app.exe');
    } catch (e) {
      print('获取更新控制器失败: $e');
    }

    // 3. 在异步方法中使用
    // Future<void> downloadAndUpdate(String url) async {
    //   final controller = ApplyUpdatesFactory.getController();
    //   // 先下载文件
    //   // 然后调用更新
    //   controller.applyUpdates(url);
    // }
  }
}

