import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData(String field, String newValue) async {
    if (newValue.isEmpty || newValue == _userData![field]) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(widget.user.uid).update({
        field: newValue,
      });

      setState(() {
        _userData![field] = newValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field berhasil diperbarui!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui $field: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false); 
    }
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Masukkan $field baru",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                Navigator.pop(context); // Tutup dialog lebih awal agar UI tidak terasa lambat
                await _updateUserData(field, newValue);
              }
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Saya'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userData == null
              ? Center(child: Text("Data tidak tersedia"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.user.email ?? "Email tidak tersedia",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          Divider(),
                          _buildEditableField("username", _userData!['username'] ?? "N/A", Icons.person),
                          _buildEditableField("phone", _userData!['phone'] ?? "N/A", Icons.phone),
                          _buildEditableField("description", _userData!['description'] ?? "N/A", Icons.info),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEditableField(String field, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        field[0].toUpperCase() + field.substring(1),
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value),
      trailing: Icon(Icons.edit, color: Colors.grey),
      onTap: () => _showEditDialog(field, value),
    );
  }
}
