import 'package:flutter/material.dart';

class ReminderPage extends StatefulWidget {
  final DateTime? initialDeadline;
  final DateTime? initialReminder;

  const ReminderPage({
    super.key,
    this.initialDeadline,
    this.initialReminder,
  });

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {

  // PILIHAN SUARA
  final List<String> reminderSounds = [
    "Default Alarm",
    "Bell Sound",
    "Morning Alarm",
    "Digital Tone",
    "Soft Notification",
  ];

  // SUARA TERPILIH
  String selectedSound = "Default Alarm";

  // STATUS REMINDER
  bool isReminderActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Reminder"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // TITLE
            const Text(
              "Reminder Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // SWITCH REMINDER
            Card(
              elevation: 3,
              child: SwitchListTile(
                title: const Text("Enable Reminder"),

                subtitle: const Text(
                  "Turn task reminder on/off",
                ),

                value: isReminderActive,

                onChanged: (value) {
                  setState(() {
                    isReminderActive = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // DROPDOWN SUARA
            const Text(
              "Choose Reminder Sound",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),

                borderRadius: BorderRadius.circular(10),
              ),

              child: DropdownButton<String>(
                value: selectedSound,

                isExpanded: true,

                underline: const SizedBox(),

                items: reminderSounds.map((String sound) {

                  return DropdownMenuItem<String>(
                    value: sound,

                    child: Text(sound),
                  );

                }).toList(),

                onChanged: (String? newValue) {

                  setState(() {
                    selectedSound = newValue!;
                  });

                  // NOTIFIKASI PILIHAN
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Sound selected: $selectedSound",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // PREVIEW
            Card(
              elevation: 3,

              child: ListTile(
                leading: const Icon(
                  Icons.music_note,
                  color: Colors.blue,
                ),

                title: const Text("Current Sound"),

                subtitle: Text(selectedSound),
              ),
            ),
          ],
        ),
      ),
    );
  }
}