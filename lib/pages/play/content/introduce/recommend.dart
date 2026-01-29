import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecommendView extends StatefulWidget {
  const RecommendView({super.key});

  @override
  State<RecommendView> createState() => _RecommendViewState();
}

class _RecommendViewState extends State<RecommendView> {
  late PlaySubjectState subjectStateController;

  @override
  void initState() {
    super.initState();
    subjectStateController = Get.find<PlaySubjectState>();
    // _searchRecommend();
  }

  // void _searchRecommend() async {
  //   final tags = subjectStateController.tags;
  //   final result = await BgmRequest.searchSubjectService(
  //       keyword: '',
  //       limit: 25,
  //       offset: 0,
  //       tags: tags.take(6).map((value) => value.name).toList());
  //   Get.log('$result');
  // }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
