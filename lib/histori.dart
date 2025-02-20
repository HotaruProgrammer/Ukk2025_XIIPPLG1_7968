import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syaifudin_hudha_test_ukk/taskdetail.dart';

class HistoryScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Tugas'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('status', isEqualTo: 'Complete')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Firestore Error: \${snapshot.error}");
            return Center(child: Text("Terjadi kesalahan: \${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Tidak ada tugas yang selesai."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var task = snapshot.data!.docs[index];
              var taskData = task.data() as Map<String, dynamic>;
              String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(
                  (taskData['createdAt'] as Timestamp).toDate());

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check_circle, color: Colors.white),
                  ),
                  title: Text(
                    taskData['task'] ?? "Tugas tanpa nama",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text('Kategori: ${taskData['category'] ?? "-"}',
                          style: TextStyle(color: Colors.blueAccent)),
                      Text('Deskripsi: ${taskData['description'] ?? "-"}'),
                      Text('Tanggal: $formattedDate',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskId: task.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
