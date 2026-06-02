import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecommendView extends StatefulWidget {
  const RecommendView({super.key});

  @override
  State<RecommendView> createState() => _RecommendViewState();
}

class _RecommendViewState extends State<RecommendView> {
  final subjectStateController = Get.find<PlaySubjectState>();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
