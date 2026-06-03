import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  DateTime today = DateTime.now();

  Map<DateTime, List<String>> tasks = {

    DateTime.utc(2026, 4, 16): [
      "Finish Research Paper",
      "Group Presentation",
    ],

    DateTime.utc(2026, 4, 20): [
      "Prepare for Quiz",
    ],
  };

  List<String> getTasksForDay(DateTime day) {

    return tasks[
            DateTime.utc(
              day.year,
              day.month,
              day.day,
            )
          ] ??
        [];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// CALENDAR
          Container(
            margin: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: TableCalendar(

              focusedDay: today,

              firstDay:
                  DateTime.utc(2000, 1, 1),

              lastDay:
                  DateTime.utc(2100, 12, 31),

              selectedDayPredicate:
                  (day) {
                return isSameDay(
                  today,
                  day,
                );
              },

              onDaySelected:
                  (selectedDay, focusedDay) {

                setState(() {
                  today = selectedDay;
                });
              },

              calendarStyle:
                  const CalendarStyle(

                todayDecoration:
                    BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),

                selectedDecoration:
                    BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),

              headerStyle:
                  const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// TITLE TASK
          Padding(
            padding: const EdgeInsets.all(16),

            child: Align(
              alignment: Alignment.centerLeft,

              child: Text(
                "Task ${today.day}/${today.month}/${today.year}",

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          /// TASK LIST
          Expanded(
            child: ListView(
              children:
                  getTasksForDay(today)
                      .map(
                (task) => taskItem(task),
              )
                      .toList(),
            ),
          ),
        ],
      ),

      /// FLOATING BUTTON
      floatingActionButton:
          FloatingActionButton(

        backgroundColor: Colors.blue,

        onPressed: () {

          showDialog(
            context: context,

            builder: (context) {

              TextEditingController
                  taskController =
                  TextEditingController();

              return AlertDialog(

                title: const Text(
                  "Add Task",
                ),

                content: TextField(
                  controller: taskController,

                  decoration:
                      const InputDecoration(
                    hintText:
                        "Input task",
                  ),
                ),

                actions: [

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Cancel",
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {

                      DateTime key =
                          DateTime.utc(
                        today.year,
                        today.month,
                        today.day,
                      );

                      if (tasks[key] != null) {

                        tasks[key]!.add(
                          taskController.text,
                        );

                      } else {

                        tasks[key] = [
                          taskController.text,
                        ];
                      }

                      setState(() {});

                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Save",
                    ),
                  ),
                ],
              );
            },
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }

  /// TASK ITEM
  Widget taskItem(String title) {

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),

      child: ListTile(
        leading: const Icon(
          Icons.calendar_today,
          color: Colors.blue,
        ),

        title: Text(title),

        trailing: const Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
      ),
    );
  }
}