import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  late String _photoUrl;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  void _loadUserData() async {
    if (widget.user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).get();
    var userData = userDoc.data() as Map<String, dynamic>;

    _nameController.text = userData['name'] ?? '';
    _photoUrl = userData['photoUrl'] ?? '';
    setState(() {});
  }

  // Pick a new image for the profile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  // Upload the image to Firebase Storage and get the URL
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      String filePath = 'profile_photos/${widget.user!.uid}.jpg';
      UploadTask uploadTask =
          FirebaseStorage.instance.ref().child(filePath).putFile(File(imageFile.path));
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // Update the user's name and photo in Firestore
  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    String name = _nameController.text.trim();
    String? photoUrl = _photoUrl;

    if (_imageFile != null) {
      photoUrl = await _uploadImage(_imageFile!); // Upload new image if selected
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).update({
        'name': name,
        'photoUrl': photoUrl ?? _photoUrl, // If no new photo, use the old one
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: _imageFile != null
                      ? FileImage(File(_imageFile!.path))
                      : (_photoUrl.isNotEmpty
                          ? NetworkImage(_photoUrl)
                          : AssetImage('assets/default_profile.png')) as ImageProvider,
                ),
              ),
              SizedBox(height: 16),
              Text("Name:"),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text("Email: ${widget.user?.email ?? 'No email'}"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Save Changes'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
