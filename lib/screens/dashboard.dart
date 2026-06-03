import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar.dart';
import 'add_task.dart';
import 'setting/setting.dart'; // 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Dashboard(),
    );
  }
}

/// DASHBOARD
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;

  /// GET PAGE
  Widget getPage() {
    switch (selectedIndex) {
      case 0:
        return dashboardContent(context);

      case 1:
        return const CalendarPage();

      case 2:
        return const AddTaskPage(); // ✅ Perbaikan: buka AddTaskPage langsung

      case 3:
        return const SettingsScreen(); // 

      default:
        return dashboardContent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      /// BODY
      body: getPage(),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// DASHBOARD CONTENT
Widget dashboardContent(BuildContext context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'StudentTask',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[400],
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Hello, Jannah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Text(
            'Stay productive today!',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          /// PROGRESS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Task realtime dari Firebase',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.5,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// QUICK ACTION
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              quickAction(context, Icons.add, 'Add Task'),
              quickAction(context, Icons.category, 'Categories'),
              quickAction(context, Icons.timer, 'Fokus Mode'),
            ],
          ),

          const SizedBox(height: 20),

          /// TITLE TASK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Upcoming Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Realtime Firebase',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// REALTIME TASK LIST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                /// LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                /// NO DATA
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada tugas"));
                }

                /// DATA
                var tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    Map<String, dynamic> data =
                        task.data() as Map<String, dynamic>;

                    /// DEADLINE
                    Timestamp? deadline = data['deadline'];
                    String deadlineText = 'Tidak ada deadline';

                    if (deadline != null) {
                      DateTime date = deadline.toDate();
                      deadlineText =
                          "${date.day}/${date.month}/${date.year}";
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            const SizedBox(height: 5),
                            Text(
                              "Deadline: $deadlineText",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(task.id)
                                .delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// QUICK ACTION
Widget quickAction(
  BuildContext context,
  IconData icon,
  String label,
) {
  return InkWell(
    onTap: () {
      if (label == 'Add Task') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTaskPage(),
          ),
        );
      }
    },
    child: Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}