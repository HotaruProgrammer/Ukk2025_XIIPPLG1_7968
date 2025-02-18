import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _logUserActivity(String activityType) async {
    if (user != null) {
      await _firestore.collection('logins').add({
        'uid': user!.uid,
        'activity': activityType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Log the login activity
    _logUserActivity('login');
  }

  @override
  void dispose() {
    // Log the logout activity when user exits the app
    _logUserActivity('logout');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histori Aktivitas dan Tugas Selesai')),
      body: ListView(
        children: [
          // Tugas yang sudah selesai
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Tugas yang Selesai",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
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
                return Center(child: Text("Terjadi kesalahan saat memuat tugas."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Tidak ada tugas yang selesai."));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var task = snapshot.data!.docs[index];
                  var taskData = task.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(taskData['task'] ?? "Tugas tanpa nama", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Selesai pada: ${taskData['createdAt'].toDate()}'),
                    ),
                  );
                },
              );
            },
          ),
          
          // Aktivitas Login
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Aktivitas Login",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('logins')
                .where('uid', isEqualTo: user?.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Terjadi kesalahan saat memuat aktivitas login."));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Tidak ada aktivitas login."));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var loginActivity = snapshot.data!.docs[index];
                  var loginData = loginActivity.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(loginData['activity'] ?? "Aktivitas tidak diketahui", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Waktu: ${loginData['timestamp'].toDate()}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
