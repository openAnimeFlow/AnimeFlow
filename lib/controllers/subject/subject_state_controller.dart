import 'package:get/get.dart';

class SubjectStateController extends GetxController {
  final RxString subjectName = ''.obs;
  final RxInt subjectId = 0.obs;

  String get name => subjectName.value;
  int get id => subjectId.value;

  void setSubject(String name, int subjectId) {
    subjectName.value = name;
    this.subjectId.value = subjectId;
  }
}
