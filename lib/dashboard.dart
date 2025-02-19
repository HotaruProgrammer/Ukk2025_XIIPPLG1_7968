import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syaifudin_hudha_test_ukk/histori.dart';
import 'package:syaifudin_hudha_test_ukk/profile.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _addTask() async {
    TextEditingController taskController = TextEditingController();
    TextEditingController categoryController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(
                  labelText: 'Masukkan tugas',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Masukkan kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Masukkan deskripsi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Simpan'),
              onPressed: () async {
                String taskText = taskController.text.trim();
                String categoryText = categoryController.text.trim();
                String descriptionText = descriptionController.text.trim();
                
                if (taskText.isNotEmpty && categoryText.isNotEmpty && descriptionText.isNotEmpty) {
                  await _firestore.collection('tasks').add({
                    'task': taskText,
                    'category': categoryText,
                    'description': descriptionText,
                    'assignedBy': user?.uid ?? '',
                    'status': 'ToDo',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard (${widget.role})')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? "User Profile"),
              accountEmail: Text(user?.email ?? "Tidak ada email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: FirebaseAuth.instance.currentUser!)));
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Log Out'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tasks').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Tidak ada tugas."));
          }

          var filteredTasks = snapshot.data!.docs.where((task) {
            var taskData = task.data() as Map<String, dynamic>;
            return taskData['status'] != 'Complete';
          }).toList();

          if (filteredTasks.isEmpty) {
            return Center(child: Text("Tidak ada tugas yang belum selesai."));
          }

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              var task = filteredTasks[index];
              var taskData = task.data() as Map<String, dynamic>;
              String taskStatus = taskData['status'] ?? 'Tidak diketahui';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(taskData['task'] ?? "Tugas tanpa nama", 
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori: ${taskData['category'] ?? "-"}'),
                      Text('Deskripsi: ${taskData['description'] ?? "-"}'),
                      Text('Status: ${taskStatus}', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: taskStatus == 'ToDo' ? Colors.red 
                               : taskStatus == 'In Progress' ? Colors.orange 
                               : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
