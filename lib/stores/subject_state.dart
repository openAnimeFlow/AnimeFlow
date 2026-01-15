import 'package:get/get.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';

class SubjectState extends GetxController {
  final RxString subjectName = ''.obs;
  final RxInt subjectId = 0.obs;
  final RxList<Tags> tags = <Tags>[].obs;

  int get id => subjectId.value;
  String get name => subjectName.value;

  void setSubject(String name, int subjectId, List<Tags> tags) {
    subjectName.value = name;
    this.tags.value = tags;
    this.subjectId.value = subjectId;
  }
}
