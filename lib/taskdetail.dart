import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _status = 'ToDo';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    try {
      DocumentSnapshot taskSnapshot =
          await _firestore.collection('tasks').doc(widget.taskId).get();

      if (taskSnapshot.exists) {
        var data = taskSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _taskController.text = data['task'] ?? '';
          _categoryController.text = data['category'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _status = data['status'] ?? 'ToDo';
          _isLoading = false;
        });
      } else {
        _showSnackbar('Tugas tidak ditemukan!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e');
      Navigator.pop(context);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateTask() async {
    if (_taskController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showSnackbar('Semua field harus diisi!');
      return;
    }

    try {
      await _firestore.collection('tasks').doc(widget.taskId).update({
        'task': _taskController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Tugas berhasil diperbarui!');
    } catch (e) {
      _showSnackbar('Gagal memperbarui tugas: $e');
    }
  }

  Future<void> _deleteTask() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Tugas'),
        content: Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        await _firestore.collection('tasks').doc(widget.taskId).delete();
        _showSnackbar('Tugas berhasil dihapus!');
        Navigator.pop(context);
      } catch (e) {
        _showSnackbar('Gagal menghapus tugas: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ToDo':
        return Colors.orange;
      case 'InProgress':
        return Colors.blue;
      case 'Complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteTask,
          ),
        ],
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _taskController,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Judul Tugas',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Description
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(_status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['ToDo', 'InProgress', 'Complete']
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _status = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _updateTask,
                              icon: Icon(Icons.save),
                              label: Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Kembali',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
