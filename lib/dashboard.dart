import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    if (await _isAdmin()) {
      try {
        await _firestore.collection('tasks').add({
          'task': taskText,
          'assignedBy': user?.uid ?? '',
          'assignedTo': "",
          'status': 'Belum Diambil',
          'createdAt': FieldValue.serverTimestamp(),
        });
        taskController.clear();
        setState(() {}); // Refresh UI setelah menambahkan tugas
      } catch (e) {
        _showSnackBar("Gagal menambahkan tugas: $e");
      }
    } else {
      _showSnackBar("Hanya admin yang bisa menambah tugas!");
    }
  }

  void _takeTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'assignedTo': user?.uid ?? '',
        'status': 'Diambil',
      });
    } catch (e) {
      _showSnackBar("Gagal mengambil tugas: $e");
    }
  }

  void _submitTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'Selesai',
      });
    } catch (e) {
      _showSnackBar("Gagal menyelesaikan tugas: $e");
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context); // Tutup drawer sebelum logout
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              accountName: Text("User Profile"),
              accountEmail: Text(user?.email ?? "Tidak ada email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Log Out'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<bool>(
            future: _isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }
              if (snapshot.data == true) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: taskController,
                          decoration: const InputDecoration(labelText: 'Tambah Tugas'),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.add), onPressed: _addTask),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('tasks').orderBy('createdAt', descending: true).snapshots(),
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
                    bool isTaskTaken = taskStatus == 'Diambil';
                    bool isAssignedToUser = (taskData['assignedTo'] ?? '') == (user?.uid ?? '');

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        title: Text(taskData['task'] ?? "Tugas tanpa nama"),
                        subtitle: Text('Status: $taskStatus'),
                        trailing: widget.role == 'member'
                            ? (taskStatus == 'Belum Diambil'
                                ? IconButton(
                                    icon: Icon(Icons.download, color: Colors.blue),
                                    onPressed: () => _takeTask(task.id),
                                  )
                                : isTaskTaken && isAssignedToUser
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
