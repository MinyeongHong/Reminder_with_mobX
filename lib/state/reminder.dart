import 'package:mobx/mobx.dart';
part 'reminder.g.dart';
// step 1 : 추상 클래스 _Reminder 선언하며 모델 생성
// step 2 : 실제 클래스 Reminder 선언하기
// step 3 : part 'reminder.g.dart'; 입력 후 터미널에서 flutter pub run build_runner watch --delete-conflicting-outputs

class Reminder = _Reminder with _$Reminder;

abstract class _Reminder with Store {
  final String id;
  final DateTime creationDate;

  @observable
  String text;

  @observable
  bool isDone;

  _Reminder(
      {required this.id,
      required this.creationDate,
      required this.text,
      required this.isDone});

  @override
  bool operator ==(covariant _Reminder other) =>
      id == other.id &&
      creationDate == other.creationDate &&
      text == other.text &&
      isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, creationDate, text, isDone);
}
