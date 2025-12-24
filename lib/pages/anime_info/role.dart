import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoleView extends StatefulWidget {
  final String title;

  const RoleView({super.key, required this.title});

  @override
  State<RoleView> createState() => _RoleViewState();
}

class _RoleViewState extends State<RoleView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                const Text('查看更多',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                Transform.rotate(
                    angle: 3 * pi / 2,
                    child:  Icon(
                      Icons.keyboard_double_arrow_down_rounded,
                      color: Theme.of(context).disabledColor,
                      size: 20,
                    ))
              ],
            )
          ],
        )
      ],
    );
  }
}
