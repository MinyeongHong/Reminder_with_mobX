import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_state_management/auth/auth_error.dart';
import 'package:mobx_state_management/state/reminder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'app_state.g.dart';

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
  @observable
  AppScreen currentScreen = AppScreen.login;

  @observable
  bool isLoading = false;

  @observable
  User? currentUser;

  @observable
  AuthError? authError;

  @observable
  ObservableList<Reminder> reminders = ObservableList<Reminder>();

  @computed
  ObservableList<Reminder> get sortedReminders =>
      ObservableList.of(reminders.sorted());

  @action
  void goTo(AppScreen screen) {
    currentScreen = screen;
  }

  @action
  Future<bool> delete(Reminder reminder) async {
    isLoading = true;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    try {
      //파이어베이스 삭제
      final firebaseReminder =
          collection.docs.firstWhere((element) => element.id == reminder.id);
      await firebaseReminder.reference.delete();
      //로컬 삭제
      reminders.removeWhere((element) => element.id == reminder.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;

    try {
      final store = FirebaseFirestore.instance;
      final operation = store.batch();
      final collection = await store.collection(userId).get();
      for (final document in collection.docs) {
        operation.delete(document.reference);
      }
      //파이어베이스에서 해당 유저의 모든 리마인더 지우기
      await operation.commit();
      //delete the user
      await user.delete();
      await auth.signOut();
      currentScreen = AppScreen.login;
      return true;
    } on FirebaseAuthException catch (e) {
      authError = AuthError.from(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logOut() async {
    isLoading = true;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    isLoading = false;
    currentScreen = AppScreen.login;
    reminders.clear();
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final userId = currentUser?.uid;
    if (userId == null) {
      isLoading = false;
      return false;
    }

    final creationDate = DateTime.now();
    final firebaseReminder =
        await FirebaseFirestore.instance.collection(userId).add({
      _DocumentKeys.text: text,
      _DocumentKeys.creationDate: creationDate,
      _DocumentKeys.isDone: false,
    });

    final reminder = Reminder(
        creationDate: creationDate,
        id: firebaseReminder.id,
        isDone: false,
        text: text);
    reminders.add(reminder);
    isLoading = false;
    return true;
  }

  @action
  Future<bool> modify(
    Reminder reminder, {
    required bool isDone,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      return false;
    }

    //update the remote reminder
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final firebaseReminder = collection.docs
        .where((element) => element.id == reminder.id)
        .first
        .reference;

    firebaseReminder.update({_DocumentKeys.isDone: isDone});
    reminders.firstWhere((element) => element.id == reminder.id).isDone =
        isDone;

    return true;
  }

  @action
  Future<void> initialize() async {
    isLoading = true;
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _loadReminders();
      currentScreen = AppScreen.reminder;
    } else {
      currentScreen = AppScreen.login;
    }
    isLoading = false;
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      return false;
    }

    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final reminders = collection.docs.map((doc) => Reminder(
        id: doc.id,
        creationDate: doc[_DocumentKeys.creationDate].toDate(),
        isDone: doc[_DocumentKeys.isDone] as bool,
        text: doc[_DocumentKeys.text] as String));

    this.reminders = ObservableList.of(reminders);
    return true;
  }

  @action
  Future<bool> _registerOrLogin({
    required LoginOrRegisterFunction fn,
    required String email,
    required String password,
  }) async {
    authError = null;
    isLoading = true;
    try {
      await fn(email: email, password: password);
      currentUser = FirebaseAuth.instance.currentUser;
      await _loadReminders();
      return true;
    } on FirebaseAuthException catch (e) {
      currentUser = null;
      authError = AuthError.from(e);
      return false;
    } finally {
      isLoading = false;
      if (currentUser != null) {
        currentScreen = AppScreen.reminder;
      }
    }
  }

  @action
  Future<bool> register({
    required String email,
    required String password,
  }) =>
      _registerOrLogin(
          fn: FirebaseAuth.instance.createUserWithEmailAndPassword,
          email: email,
          password: password);

  @action
  Future<bool> login({
    required String email,
    required String password,
  }) =>
      _registerOrLogin(
          fn: FirebaseAuth.instance.signInWithEmailAndPassword,
          email: email,
          password: password);
}

abstract class _DocumentKeys {
  static const text = 'text';
  static const creationDate = 'creation_date';
  static const isDone = 'is_done';
}

typedef LoginOrRegisterFunction = Future<UserCredential> Function(
    {required String email, required String password});

extension ToInit on bool {
  int toInteger() => this ? 1 : 0;
}

//멀티 필드 정렬
extension Sorted on List<Reminder> {
  List<Reminder> sorted() => [...this]..sort((lhs, rhs) {
      final isDone = lhs.isDone.toInteger().compareTo(rhs.isDone.toInteger());
      if (isDone != 0) {
        return isDone;
      }
      return lhs.creationDate.compareTo(rhs.creationDate);
    });
}

enum AppScreen { login, register, reminder }
