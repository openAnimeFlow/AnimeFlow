import 'package:flutter/material.dart';

/// 通用下拉菜单组件
class DropDownMenu<T> extends StatelessWidget {
  /// 菜单项列表
  final List<T> items;

  /// 当前选中的项（可为空）
  final T? selectedItem;

  /// 按钮构建器
  final Widget Function(BuildContext context, T? selectedItem) buttonBuilder;

  /// 菜单项构建器
  final Widget Function(BuildContext context, T item, bool isSelected)
      itemBuilder;

  /// 选择回调
  final void Function(T item) onSelected;

  /// 菜单偏移量
  final Offset offset;

  /// 菜单形状
  final ShapeBorder? shape;

  /// 是否禁用选中的项
  final bool disableSelected;

  const DropDownMenu({
    super.key,
    required this.items,
    this.selectedItem,
    required this.buttonBuilder,
    required this.itemBuilder,
    required this.onSelected,
    this.offset = const Offset(0, 40),
    this.shape,
    this.disableSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      offset: offset,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
      itemBuilder: (BuildContext context) {
        return items.map((item) {
          final isSelected = item == selectedItem;
          return PopupMenuItem<T>(
            value: item,
            enabled: disableSelected ? !isSelected : true,
            child: itemBuilder(context, item, isSelected),
          );
        }).toList();
      },
      onSelected: onSelected,
      child: buttonBuilder(context, selectedItem),
    );
  }
}

