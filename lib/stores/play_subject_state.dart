import 'package:get/get.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';

class PlaySubjectState extends GetxController {
  final RxString subjectName = ''.obs;
  final RxInt subjectId = 0.obs;

  int get id => subjectId.value;
  String get name => subjectName.value;

  void setSubject(String name, int subjectId) {
    subjectName.value = name;
    this.subjectId.value = subjectId;
  }
}
