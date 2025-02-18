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
  final TextEditingController taskController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool? _isAdminCache;

  Future<bool> _isAdmin() async {
    if (_isAdminCache != null) return _isAdminCache!;
    if (user == null) return false;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
      bool isAdmin = userDoc.exists && (userDoc['role'] == 'admin');
      setState(() {
        _isAdminCache = isAdmin;
      });
      return isAdmin;
    } catch (_) {
      return false;
    }
  }

  void _addTask() async {
    String taskText = taskController.text.trim();
    if (taskText.isEmpty) {
      _showSnackBar("Tugas tidak boleh kosong");
      return;
    }
    try {
      await _firestore.collection('tasks').add({
        'task': taskText,
        'assignedBy': user?.uid ?? '',
        'assignedTo': "", 
        'status': 'ToDo',
        'createdAt': FieldValue.serverTimestamp(),
      });
      taskController.clear();
      setState(() {});
    } catch (e) {
      _showSnackBar("Gagal menambahkan tugas: $e");
    }
  }

  void _editTask(String taskId, String currentTask) async {
    TextEditingController editController = TextEditingController(text: currentTask);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Tugas'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(labelText: 'Edit Tugas'),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Simpan'),
              onPressed: () async {
                String updatedTask = editController.text.trim();
                if (updatedTask.isNotEmpty) {
                  await _firestore.collection('tasks').doc(taskId).update({
                    'task': updatedTask,
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

  void _deleteTask(String taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Tugas'),
          content: Text('Apakah Anda yakin ingin menghapus tugas ini?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () async {
                await _firestore.collection('tasks').doc(taskId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _takeTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'assignedTo': user?.uid ?? '',  
        'status': 'In Progress',  
      });
      _showSnackBar("Tugas berhasil diambil");
    } catch (e) {
      _showSnackBar("Gagal mengambil tugas: $e");
    }
  }

  void _submitTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'Complete',  
      });
      _firestore.collection('tasks').doc(taskId).delete();
      _showSnackBar("Tugas berhasil diselesaikan dan dihapus");
    } catch (e) {
      _showSnackBar("Gagal menyelesaikan tugas: $e");
    }
  }

  void _openTaskDetail(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: taskId),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Log Out'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Ya'),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: user))); 
              },
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); 
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); 
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
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tambah Tugas",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      labelText: 'Tugas Baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _addTask,
                      icon: Icon(Icons.add, color: Colors.blue),
                      label: Text(
                        "Tambah",
                        style: TextStyle(color: Colors.blue),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan saat memuat tugas."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Tidak ada tugas."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var task = snapshot.data!.docs[index];
                    var taskData = task.data() as Map<String, dynamic>;
                    String taskStatus = taskData['status'] ?? 'Tidak diketahui';

                    // Skip tasks that are complete (removed)
                    if (taskStatus == 'Complete') return SizedBox.shrink();

return Card(
  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    title: Text(taskData['task'] ?? "Tugas tanpa nama", style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Row(
      children: [
        Text('Status: $taskStatus'),
        Spacer(),
        DropdownButton<String>(
          value: taskStatus,
          onChanged: (newStatus) {
            _firestore.collection('tasks').doc(task.id).update({
              'status': newStatus,
            });
          },
          items: <String>['ToDo', 'In Progress', 'Complete']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    ),
    onTap: () => _openTaskDetail(task.id),
    trailing: widget.role == 'member' || widget.role == 'admin'
        ? (taskStatus == 'ToDo'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.download, color: Colors.blue),
                    onPressed: () => _takeTask(task.id),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editTask(task.id, taskData['task']),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(task.id),
                  ),
                ],
              )
            : taskStatus == 'In Progress'
                ? IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _submitTask(task.id),
                  )
                : null)
        : null,
  ),
);

                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    TextEditingController progressController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Task Detail')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('tasks').doc(taskId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Task not found"));
          }

          var taskData = snapshot.data!.data() as Map<String, dynamic>;
          String taskStatus = taskData['status'] ?? 'Tidak diketahui';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task: ${taskData['task']}",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text("Status: $taskStatus"),
                SizedBox(height: 20),
                if (taskStatus != 'Complete')
                  TextField(
                    controller: progressController,
                    decoration: InputDecoration(
                      labelText: 'Update Progress',
                      border: OutlineInputBorder(),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String progressText = progressController.text.trim();
                    if (progressText.isNotEmpty) {
                      await _firestore.collection('tasks').doc(taskId).update({
                        'progress': progressText,
                        'status': 'In Progress',
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Update Progress'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
