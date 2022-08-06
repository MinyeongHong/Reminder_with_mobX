import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx_state_management/dialogs/delete_reminder_dialog.dart';
import 'package:mobx_state_management/dialogs/show_textfield_dialog.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'main_popup_menu_button.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Reminders"),
          actions: [
            IconButton(
                onPressed: () async {
                  final reminderText = await showTextFieldDialog(
                      context: context,
                      title: "리마인더에 작성할 일",
                      hintText: "텍스트를 작성하세요",
                      optionsBuilder: () => {
                            TextFieldDialogButtonType.cancel: "취소",
                            TextFieldDialogButtonType.confirm: "저장",
                          });

                  if (reminderText == null) {
                    return;
                  }
                  context.read<AppState>().createReminder(reminderText);
                },
                icon: Icon(Icons.add)),
            const MainPopupMenuButton()
          ],
        ),
        body: const ReminderListView());
  }
}

class ReminderListView extends StatelessWidget {
  const ReminderListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Observer(builder: (context) {
      return ListView.builder(
        itemCount: appState.sortedReminders.length,
        itemBuilder: (context, index) {
          final reminder = appState.sortedReminders[index];
          return Observer(
              builder: (context){
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: reminder.isDone,
              onChanged: (isDone) {
                appState.modify(reminder, isDone: isDone ?? false);
                reminder.isDone = isDone ?? false;
              },
              title: Row(
                children: [
                  Expanded(child: Text(reminder.text)),
                  IconButton(onPressed: () async{
                    final shouldDeleteReminder = await showDeleteReminderDialog(context);
                    if(shouldDeleteReminder) {appState.delete(reminder);}
                  }, icon: const Icon(Icons.delete))

                ],
              ),
            );
          });

        },
      );
    });
  }
}
