import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailOrUsernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _login() async {
    String emailOrUsername = emailOrUsernameController.text.trim();
    String password = passwordController.text.trim();

    if (emailOrUsername.isEmpty || password.isEmpty) {
      _showAlert('Harap isi semua bidang');
      return;
    }

    try {
      String email = emailOrUsername;
      if (!emailOrUsername.contains('@')) {
        try {
          QuerySnapshot userSnapshot = await _firestore
              .collection('users')
              .where('username', isEqualTo: emailOrUsername)
              .get();

          print("📄 Jumlah Dokumen Ditemukan: ${userSnapshot.docs.length}");

          if (userSnapshot.docs.isEmpty) {
            _showAlert('Username tidak ditemukan.');
            return;
          }

          Map<String, dynamic>? userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;

          print("📊 Data Pengguna: $userData");

          if (userData == null || !userData.containsKey('email') || userData['email'].isEmpty) {
            _showAlert('Data pengguna tidak valid.');
            return;
          }

          email = userData['email'];
          print("📧 Email ditemukan: $email");
        } catch (e) {
          print("🔥 Firestore Query Error: $e");
          _showAlert('Gagal mengambil data pengguna.');
          return;
        }
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showAlert('Pengguna belum login.');
        return;
      }
      print("✅ Login berhasil untuk user: ${user.email}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(role: 'member'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("⚠️ FirebaseAuth Error: ${e.code}, Message: ${e.message}");
      if (e.code == 'wrong-password') {
        _showAlert('Password salah. Silakan coba lagi.');
      } else if (e.code == 'user-not-found') {
        _showAlert('Pengguna tidak ditemukan.');
      } else if (e.code == 'invalid-email') {
        _showAlert('Format email tidak valid.');
      } else {
        _showAlert(e.message ?? 'Login gagal');
      }
    } catch (e) {
      print("🚨 Unexpected Error: $e");
      _showAlert('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

  // Alert function
  void _showAlert(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 12,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: emailOrUsernameController,
                        label: 'Email atau Username',
                        hint: 'Masukkan email atau username',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        label: 'Password',
                        hint: 'Masukkan password',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Belum punya akun? Daftar sekarang',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}
