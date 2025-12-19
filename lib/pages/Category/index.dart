import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: OutlinedButton(
            onPressed: () async {
            },
            child: const Text("查看全部配置")));
  }
}
