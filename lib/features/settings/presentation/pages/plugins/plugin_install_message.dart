import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/source/data/repositories/source_repository.dart';

/// 把规则下载/更新失败转成用户可读的文案。
///
/// 「规则需要更高版本客户端」单独提示，避免和网络错误、格式错误混在一起
/// 让用户误以为重试就能解决。
String pluginInstallErrorMessage(
  AppLocalizations l10n,
  String pluginName,
  Object error, {
  required bool isUpdate,
}) {
  if (error is PluginInstallException &&
      error.failure == PluginInstallFailure.requiresNewerClient) {
    return l10n.pluginRequiresNewerClient(pluginName);
  }

  final detail =
      error is PluginInstallException ? error.message : error.toString();
  return isUpdate
      ? l10n.pluginUpdateFailed(pluginName, detail)
      : l10n.pluginDownloadFailed(pluginName, detail);
}
