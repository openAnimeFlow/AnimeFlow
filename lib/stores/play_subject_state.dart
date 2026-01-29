import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:get/get.dart';

class PlaySubjectState extends GetxController {
  late Rx<SubjectBasicData> subject;

  PlaySubjectState(SubjectBasicData subject) {
    this.subject = subject.obs;
  }
}
