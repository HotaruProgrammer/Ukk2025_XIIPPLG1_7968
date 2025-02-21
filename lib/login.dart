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
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    String emailOrUsername = emailOrUsernameController.text.trim();
    String password = passwordController.text.trim();

    if (emailOrUsername.isEmpty || password.isEmpty) {
      _showAlert('Harap isi semua bidang');
      setState(() => _isLoading = false);
      return;
    }

    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains('@')) {
        QuerySnapshot userSnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();

        if (userSnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Username tidak ditemukan.',
          );
        }

        var userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;
        email = userData?['email'] ?? '';

        if (email.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Data pengguna tidak valid.',
          );
        }
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Login berhasil untuk user: $email");
      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Password salah. Silakan coba lagi.';
          break;
        case 'user-not-found':
          errorMessage = 'Pengguna tidak ditemukan. Periksa email atau username.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password salah.';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      _showAlert(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(role: 'member'),
      ),
    );
  }

  void _showAlert(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: message.length > 50 ? 3 : 2),
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
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
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
