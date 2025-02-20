import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syaifudin_hudha_test_ukk/histori.dart';
import 'package:syaifudin_hudha_test_ukk/profile.dart';
import 'package:syaifudin_hudha_test_ukk/taskdetail.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';

  Future<String> getUsername(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.exists ? userDoc['username'] ?? "User Profile" : "User Profile";
    } catch (e) {
      print("❌ Error mengambil username: $e");
      return "User Profile";
    }
  }

  Future<void> _addTask() async {
    TextEditingController taskController = TextEditingController();
    TextEditingController categoryController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(controller: taskController, label: 'Masukkan tugas'),
                const SizedBox(height: 10),
                _buildTextField(controller: categoryController, label: 'Masukkan kategori'),
                const SizedBox(height: 10),
                _buildTextField(controller: descriptionController, label: 'Masukkan deskripsi'),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () async {
                if ([taskController, categoryController, descriptionController].every((c) => c.text.trim().isNotEmpty)) {
                  await _firestore.collection('tasks').add({
                    'task': taskController.text.trim(),
                    'category': categoryController.text.trim(),
                    'description': descriptionController.text.trim(),
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

  TextField _buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

void _confirmLogout() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi"),
        content: const Text("Apakah yakin anda ingin keluar?"),
        actions: [
          TextButton(
            child: const Text("Tidak"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Ya"),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: TaskSearchDelegate(_firestore)),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(todayDate),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildUserHeader("Memuat...");
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return _buildUserHeader("User Profile");
              }
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              return _buildUserHeader(userData['username'] ?? "User Profile");
            },
          ),
          _buildDrawerItem(Icons.person, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: user!)))),
          _buildDrawerItem(Icons.history, 'History', () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()))),
          const Divider(),
          _buildDrawerItem(Icons.exit_to_app, 'Log Out', _confirmLogout),
        ],
      ),
    );
  }

  UserAccountsDrawerHeader _buildUserHeader(String username) {
    return UserAccountsDrawerHeader(
      accountName: Text(username),
      accountEmail: Text(user?.email ?? "Tidak ada email"),
      currentAccountPicture: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
      ),
      decoration: const BoxDecoration(color: Colors.blueAccent),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildHeader(String todayDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Text(
        'Today: $todayDate',
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tasks').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Tidak ada tugas."));

        var filteredTasks = snapshot.data!.docs.where((task) {
          var taskData = task.data() as Map<String, dynamic>;
          return _searchQuery.isEmpty
              ? taskData['status'] != 'Complete'
              : taskData['task'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                taskData['category'].toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredTasks.isEmpty) return const Center(child: Text("Tidak ada tugas yang ditemukan."));

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index]),
        );
      },
    );
  }

  Card _buildTaskCard(QueryDocumentSnapshot task) {
    var taskData = task.data() as Map<String, dynamic>;
    String taskStatus = taskData['status'] ?? 'Tidak diketahui';
    Timestamp createdAt = taskData['createdAt'] ?? Timestamp.now();
    String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(createdAt.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(taskData['task'] ?? "Tugas tanpa nama", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori: ${taskData['category'] ?? "-"}'),
            Text('Deskripsi: ${taskData['description'] ?? "-"}'),
            Text('Status: $taskStatus', style: TextStyle(fontWeight: FontWeight.bold, color: taskStatus == 'ToDo' ? Colors.red : taskStatus == 'In Progress' ? Colors.orange : Colors.green)),
            Text('Tanggal: $formattedDate'),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: task.id))),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final FirebaseFirestore firestore;

  TaskSearchDelegate(this.firestore);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => query.isEmpty
      ? const Center(child: Text("Silakan masukkan kata kunci untuk mencari."))
      : StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('tasks')
              .where('category', isGreaterThanOrEqualTo: query)
              .where('category', isLessThanOrEqualTo: query + '\uf8ff')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var results = snapshot.data!.docs;
            if (results.isEmpty) return const Center(child: Text("Tidak ada tugas yang ditemukan."));

            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                var task = results[index].data() as Map<String, dynamic>;
                Timestamp createdAt = task['createdAt'] ?? Timestamp.now();
                String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(createdAt.toDate());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(task['task'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori: ${task['category']}', style: const TextStyle(color: Colors.blueAccent)),
                        const SizedBox(height: 5),
                        Text('Status: ${task['status']}', style: TextStyle(color: task['status'] == 'ToDo' ? Colors.red : task['status'] == 'In Progress' ? Colors.orange : Colors.green, fontWeight: FontWeight.w600)),
                        Text('Tanggal: $formattedDate'),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: results[index].id))),
                  ),
                );
              },
            );
          },
        );

  @override
  Widget buildSuggestions(BuildContext context) => query.isEmpty
      ? const Center(child: Text("Silakan masukkan kata kunci untuk mencari."))
      : buildResults(context);
}
