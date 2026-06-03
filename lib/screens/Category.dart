import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: ListView(
          children: [

            // CATEGORY ITEM
            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.school,
                  color: Colors.blue,
                ),

                title: const Text("School"),

                subtitle: const Text(
                  "Task for school activities",
                ),

                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CATEGORY ITEM
            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.work,
                  color: Colors.green,
                ),

                title: const Text("Work"),

                subtitle: const Text(
                  "Task for work activities",
                ),

                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CATEGORY ITEM
            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Colors.orange,
                ),

                title: const Text("Personal"),

                subtitle: const Text(
                  "Personal daily task",
                ),

                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),
          ],
        ),
      ),

      // FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          // ACTION ADD CATEGORY
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Add Category Clicked"),
            ),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}