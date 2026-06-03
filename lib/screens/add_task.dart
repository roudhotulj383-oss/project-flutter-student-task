import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar.dart';
import 'category.dart';
import 'reminder.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController descController =
      TextEditingController();
      DateTime? selectedDeadline;

  List<TextEditingController> subtasks = [
    TextEditingController(),
  ];

  List<bool> subtaskDone = [
    false,
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Add Task",
          style: TextStyle(
            color: Colors.black,
          ),
        ),

        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.edit,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade300,
                    Colors.blue.shade500,
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  /// TITLE
                  TextField(
                    controller: titleController,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration:
                        const InputDecoration(
                      hintText: "Nama Task",

                      hintStyle: TextStyle(
                        color: Colors.white70,
                      ),

                      border: InputBorder.none,
                    ),
                  ),

                  /// DESCRIPTION
                  TextField(
                    controller: descController,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration:
                        const InputDecoration(
                      hintText: "Deskripsi",

                      hintStyle: TextStyle(
                        color: Colors.white70,
                      ),

                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// MENU
            ListTile(
            leading: const Icon(
            Icons.calendar_today,
            color: Colors.blue,
          ),

          title: const Text(
          "Deadline Task",
  ),

          subtitle: Text(
          selectedDeadline == null
        ? "Pilih deadline"
        : "${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}",
  ),

      onTap: () async {

    DateTime? pickedDate =
        await showDatePicker(
      context: context,

      initialDate: DateTime.now(),

      firstDate: DateTime(2024),

      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {

      setState(() {

        selectedDeadline =
            pickedDate;
      });
    }
  },
),

            buildMenu(
              Icons.folder,
              "Category",
              const CategoryPage(),
            ),

            buildMenu(
              Icons.notifications,
              "Reminder",
              const ReminderPage(),
            ),

            const SizedBox(height: 20),

            /// SUBTASK TITLE
            const Text(
              "Subtasks",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// SUBTASK LIST
            Column(
              children: List.generate(
                subtasks.length,
                (index) {

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),

                    child: Row(
                      children: [

                        Checkbox(
                          value: subtaskDone[index],

                          onChanged: (val) {
                            setState(() {
                              subtaskDone[index] =
                                  val!;
                            });
                          },
                        ),

                        Expanded(
                          child: TextField(
                            controller:
                                subtasks[index],

                            decoration:
                                const InputDecoration(
                              hintText:
                                  "Add Subtask",

                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// ADD SUBTASK BUTTON
            ElevatedButton(
              onPressed: () {

                setState(() {

                  subtasks.add(
                    TextEditingController(),
                  );

                  subtaskDone.add(false);
                });
              },

              child: const Text(
                "Add Subtask",
              ),
            ),

            const SizedBox(height: 20),

        /// SAVE TASK BUTTON
ElevatedButton(
  onPressed: () async {

    String title =
        titleController.text;

    String desc =
        descController.text;

    if (title.isEmpty) {
      return;
    }

    /// SUBTASK DATA
    List<Map<String, dynamic>>
        subtaskList = [];

    for (
      int i = 0;
      i < subtasks.length;
      i++
    ) {

      subtaskList.add({
        'title':
            subtasks[i].text,

        'done':
            subtaskDone[i],
      });
    }

    
  print("SAVE BERHASIL"); 
    await FirebaseFirestore
        .instance
        .collection('tasks')
        .add({

      'title': title,

      'description': desc,

      'subtasks': subtaskList,
      'deadline': selectedDeadline != null
    ? Timestamp.fromDate(
        selectedDeadline!,
      )
    : null,

       'deadline': null,

  'createdAt': Timestamp.now(),
});

    /// SUCCESS MESSAGE
    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content: Text(
          "Task berhasil disimpan",
        ),
      ),
    );

    /// CLEAR FORM
    titleController.clear();

    descController.clear();

    setState(() {

      subtasks = [
        TextEditingController(),
      ];

      subtaskDone = [
        false,
      ];
    });
  },

  child: const Text(
    "Save Task",
  ),
),
          ],
        ),
      ),
      /// BOTTOM NAVIGATION
      bottomNavigationBar:
          BottomNavigationBar(

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: "Task",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.calendar_today),
            label: "Calendar",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Report",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  /// MENU WIDGET
  Widget buildMenu(
    IconData icon,
    String title,
    Widget page,
  ) {

    return InkWell(

      onTap: () {

        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: Colors.blue,
            ),

            const SizedBox(width: 10),

            Text(title),

            const Spacer(),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}