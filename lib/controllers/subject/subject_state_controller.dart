import 'package:get/get.dart';

class SubjectStateController extends GetxController {
  final RxString subjectName = ''.obs;
  final RxInt subjectId = 0.obs;

  void setSubject(String name, int subjectId) {
    subjectName.value = name;
    this.subjectId.value = subjectId;
  }
}
